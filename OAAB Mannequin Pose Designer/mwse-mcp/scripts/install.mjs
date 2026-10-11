#!/usr/bin/env node
// Register (or remove) the mwse-mcp MCP server with the local AI hosts.
//
// Mirrors codex-claude-bridge's src/install.ts: an install/uninstall action with
// --dry-run, automatic .bak backups, and idempotent "already up to date" checks.
// Edits each host's MCP config in place:
//   - Claude Code   ~/.claude.json                              (JSON, mcpServers)
//   - Cline         ~/.cline/data/settings/cline_mcp_settings.json (JSON, mcpServers)
//   - GitHub Copilot ~/.copilot/mcp-config.json                  (JSON, mcpServers)
//   - Codex CLI      ~/.codex/config.toml                       (TOML, mcp_servers)
//   - Antigravity   ~/.gemini/.../mcp_config.json               (JSON, mcpServers)
//   - Pi            ~/.pi/agent/mcp.json                        (JSON, mcpServers)
//   - OpenCode      ~/.config/opencode/opencode.json            (JSONC, mcp)
//   - Freebuff      ~/.agents/mcp.json                          (JSON, mcpServers)
// plus the `mod` pseudo-host, which copies mwse/mwseMCP into the game's
// Data Files/MWSE/mods (skipped when that path is a dev junction).
//
// The server runs over stdio as `node <repo>/dist/index.js` and needs
// MORROWIND_ROOT in its env, which we inject into each host entry. The root
// comes from --morrowind-root, then $MORROWIND_ROOT, then the registry, then a
// prompt.
//
// Without --host, install targets only the hosts that look installed (their
// config dir exists) plus `mod`; uninstall targets all of them.
//
// Usage:
//   node scripts/install.mjs [install|uninstall] [--dry-run]
//                            [--morrowind-root <path>] [--host mod,claude,cline,copilot,codex,antigravity,pi,opencode,freebuff]
//   npm run install:mcp        # install to all detected hosts
//   npm run uninstall:mcp      # remove from all hosts

import { copyFile, cp, lstat, mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { createInterface } from "node:readline/promises";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { parse as parseToml, stringify as stringifyToml } from "smol-toml";

const SERVER_NAME = "mwse-mcp";
const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, "..");
const distEntry = join(repoRoot, "dist", "index.js");
const modSource = join(repoRoot, "mwse", "mwseMCP");

const ALL_HOSTS = ["mod", "claude", "cline", "copilot", "codex", "antigravity", "pi", "opencode", "freebuff"];

const home = homedir();
const claudeConfigPath = join(home, ".claude.json");
const copilotConfigPath = join(home, ".copilot", "mcp-config.json");
const codexConfigPath = join(home, ".codex", "config.toml");
// Freebuff's global config, on every platform. It also reads per-project
// `.agents/mcp.json` files, which we leave alone.
const freebuffConfigPath = join(home, ".agents", "mcp.json");

function clineConfigPath() {
  const explicitPath = process.env.CLINE_MCP_SETTINGS_PATH?.trim();
  if (explicitPath) return explicitPath;

  const explicitDataDir = process.env.CLINE_DATA_DIR?.trim();
  if (explicitDataDir) {
    return join(explicitDataDir, "settings", "cline_mcp_settings.json");
  }

  const clineDir = process.env.CLINE_DIR?.trim() || join(home, ".cline");
  return join(clineDir, "data", "settings", "cline_mcp_settings.json");
}

// Antigravity has two known config locations; prefer the newer one if present.
const antigravityPreferred = join(home, ".gemini", "config", "mcp_config.json");
const antigravityFallback = join(home, ".gemini", "antigravity-cli", "mcp_config.json");
function antigravityInstallPath() {
  if (existsSync(antigravityPreferred)) return antigravityPreferred;
  if (existsSync(join(home, ".gemini", "config"))) return antigravityPreferred;
  return antigravityFallback;
}

// Pi's agent dir is ~/.pi/agent on every platform, overridable via env.
function piConfigPath() {
  const agentDir = process.env.PI_CODING_AGENT_DIR?.trim() || join(home, ".pi", "agent");
  return join(agentDir, "mcp.json");
}

// OpenCode reads two env overrides, then prefers an existing .jsonc over .json.
function openCodeConfigPath() {
  const explicitPath = process.env.OPENCODE_CONFIG_PATH?.trim();
  if (explicitPath) return explicitPath;

  const customConfig = process.env.OPENCODE_CONFIG?.trim();
  if (customConfig) return customConfig;

  const configDir = join(home, ".config", "opencode");
  const jsoncPath = join(configDir, "opencode.jsonc");
  if (existsSync(jsoncPath)) return jsoncPath;
  return join(configDir, "opencode.json");
}

function parseArgs(argv) {
  const args = argv.slice(2);
  const action = args.some((a) => ["uninstall", "--uninstall", "-u"].includes(a))
    ? "uninstall"
    : "install";
  const dryRun = args.includes("--dry-run") || args.includes("-d");

  const rootIdx = args.indexOf("--morrowind-root");
  const explicitRoot = rootIdx !== -1 && args[rootIdx + 1]
    ? args[rootIdx + 1]
    : process.env.MORROWIND_ROOT?.trim() || undefined;

  const hostIdx = args.indexOf("--host");
  const explicitHosts = hostIdx !== -1 && args[hostIdx + 1]
    ? args[hostIdx + 1].split(",").map((h) => h.trim().toLowerCase())
    : undefined;

  return { action, dryRun, explicitRoot, explicitHosts };
}

const isMorrowindRoot = (dir) => existsSync(join(dir, "Morrowind.exe"));

// The Bethesda key is written by the CD/GOG/Steam installs and the launcher.
function registryMorrowindRoot() {
  if (process.platform !== "win32") return undefined;
  for (const key of [
    "HKLM\\SOFTWARE\\WOW6432Node\\Bethesda Softworks\\Morrowind",
    "HKLM\\SOFTWARE\\Bethesda Softworks\\Morrowind",
  ]) {
    const { stdout } = spawnSync("reg", ["query", key, "/v", "Installed Path"], { encoding: "utf8" });
    const match = stdout?.match(/Installed Path\s+REG_SZ\s+(.+)/);
    const dir = match?.[1].trim();
    if (dir && isMorrowindRoot(dir)) return dir;
  }
  return undefined;
}

async function promptMorrowindRoot(detected) {
  if (!process.stdin.isTTY) return detected;
  const rl = createInterface({ input: process.stdin, output: process.stdout });
  try {
    for (;;) {
      const hint = detected ? ` [${detected}]` : "";
      const answer = (await rl.question(`Morrowind install folder (the one with Morrowind.exe)${hint}: `))
        .trim().replace(/^"|"$/g, "");
      if (!answer && detected) return detected;
      if (!answer) return undefined;
      if (isMorrowindRoot(answer)) return answer;
      console.log(`  No Morrowind.exe in ${answer}. Try again, or press Enter to cancel.`);
    }
  } finally {
    rl.close();
  }
}

async function resolveMorrowindRoot(explicitRoot) {
  if (explicitRoot) return resolve(explicitRoot);
  const root = await promptMorrowindRoot(registryMorrowindRoot());
  return root && resolve(root);
}

// A host counts as present when its config dir exists, so a default install
// doesn't scatter config files for tools this machine has never run.
function detectedHosts() {
  const present = {
    claude: existsSync(claudeConfigPath) || existsSync(join(home, ".claude")),
    cline: existsSync(dirname(dirname(dirname(clineConfigPath())))),
    copilot: existsSync(dirname(copilotConfigPath)),
    codex: existsSync(dirname(codexConfigPath)),
    antigravity: existsSync(join(home, ".gemini")),
    pi: existsSync(dirname(piConfigPath())),
    opencode: existsSync(dirname(openCodeConfigPath())),
    freebuff: existsSync(dirname(freebuffConfigPath)),
  };
  return ["mod", ...Object.keys(present).filter((h) => present[h])];
}

/**
 * Order-insensitive canonical JSON: recursively sorts object keys (arrays keep
 * their order). Lets the idempotency check survive a TOML round-trip, which moves
 * nested tables (e.g. `env`) to the end and so reorders keys vs. our `expected`.
 */
function canonical(value) {
  if (Array.isArray(value)) return value.map(canonical);
  if (value && typeof value === "object") {
    return Object.fromEntries(
      Object.keys(value).sort().map((k) => [k, canonical(value[k])]),
    );
  }
  return value;
}

async function safeReadText(path) {
  try {
    return await readFile(path, "utf8");
  } catch {
    return "";
  }
}

async function backupFile(path, dryRun) {
  if (!existsSync(path)) return;
  const backupPath = `${path}.bak`;
  if (dryRun) {
    console.log(`[~] DRY RUN: would back up ${path} -> ${backupPath}`);
  } else {
    await copyFile(path, backupPath);
    console.log(`[+] Backed up ${path} -> ${backupPath}`);
  }
}

/**
 * Apply one host config. `read`/`write` (de)serialize; `getServers`/`setServers`
 * navigate to the server map; `entry()` builds the expected server definition.
 * Keeps the install/uninstall/dry-run/idempotency logic in one place so the
 * supported hosts only differ in their format and key names.
 */
async function applyHost({ label, path, action, dryRun, read, write, getServers, setServers, entry }) {
  console.log(`\n--- ${label} (${path}) ---`);
  const content = await safeReadText(path);
  let config = {};
  if (content.trim()) {
    try {
      config = read(content);
    } catch {
      console.error(`[x] Failed to parse ${path}. Fix it first, then re-run.`);
      return;
    }
  } else if (action === "uninstall") {
    console.log(`[-] File not found or empty. Skipping.`);
    return;
  }

  const servers = getServers(config) ?? {};

  if (action === "install") {
    const expected = entry();
    if (JSON.stringify(canonical(servers[SERVER_NAME])) === JSON.stringify(canonical(expected))) {
      console.log(`[-] '${SERVER_NAME}' already present and up to date.`);
      return;
    }
    if (dryRun) {
      console.log(`[~] DRY RUN: would set '${SERVER_NAME}' to:`);
      console.log(JSON.stringify(expected, null, 2));
      return;
    }
    await backupFile(path, dryRun);
    servers[SERVER_NAME] = expected;
    setServers(config, servers);
    await mkdir(dirname(path), { recursive: true });
    await writeFile(path, write(config));
    console.log(`[+] Registered '${SERVER_NAME}'.`);
  } else {
    if (!servers[SERVER_NAME]) {
      console.log(`[-] '${SERVER_NAME}' not found. Skipping.`);
      return;
    }
    if (dryRun) {
      console.log(`[~] DRY RUN: would remove '${SERVER_NAME}'.`);
      return;
    }
    await backupFile(path, dryRun);
    delete servers[SERVER_NAME];
    setServers(config, servers);
    await writeFile(path, write(config));
    console.log(`[+] Removed '${SERVER_NAME}'.`);
  }
}

async function handleClaude(action, dryRun, morrowindRoot) {
  await applyHost({
    label: "Claude Code MCP config",
    path: claudeConfigPath,
    action,
    dryRun,
    read: JSON.parse,
    write: (c) => JSON.stringify(c, null, 2),
    getServers: (c) => c.mcpServers,
    setServers: (c, s) => {
      if (Object.keys(s).length === 0) delete c.mcpServers;
      else c.mcpServers = s;
    },
    entry: () => ({
      type: "stdio",
      command: "node",
      args: [distEntry],
      env: { MORROWIND_ROOT: morrowindRoot },
    }),
  });
}

async function handleCline(action, dryRun, morrowindRoot) {
  await applyHost({
    label: "Cline MCP config",
    path: clineConfigPath(),
    action,
    dryRun,
    read: JSON.parse,
    write: (c) => JSON.stringify(c, null, 2),
    getServers: (c) => c.mcpServers,
    setServers: (c, s) => {
      if (Object.keys(s).length === 0) delete c.mcpServers;
      else c.mcpServers = s;
    },
    entry: () => ({
      transport: {
        type: "stdio",
        command: "node",
        args: [distEntry],
        env: { MORROWIND_ROOT: morrowindRoot },
      },
      timeout: 86400,
    }),
  });
}

async function handleCopilot(action, dryRun, morrowindRoot) {
  await applyHost({
    label: "GitHub Copilot CLI MCP config",
    path: copilotConfigPath,
    action,
    dryRun,
    read: JSON.parse,
    write: (c) => JSON.stringify(c, null, 2),
    getServers: (c) => c.mcpServers,
    setServers: (c, s) => {
      if (Object.keys(s).length === 0) delete c.mcpServers;
      else c.mcpServers = s;
    },
    entry: () => ({
      type: "stdio",
      command: "node",
      args: [distEntry],
      env: { MORROWIND_ROOT: morrowindRoot },
    }),
  });
}

async function handleCodex(action, dryRun, morrowindRoot) {
  await applyHost({
    label: "Codex config",
    path: codexConfigPath,
    action,
    dryRun,
    read: parseToml,
    write: stringifyToml,
    getServers: (c) => c.mcp_servers,
    setServers: (c, s) => {
      if (Object.keys(s).length === 0) delete c.mcp_servers;
      else c.mcp_servers = s;
    },
    // Generous timeout: mw_wait_for_event can legitimately block for minutes.
    entry: () => ({
      command: "node",
      args: [distEntry],
      env: { MORROWIND_ROOT: morrowindRoot },
      tool_timeout_sec: 86400,
    }),
  });
}

async function handleAntigravity(action, dryRun, morrowindRoot) {
  // On uninstall, clean both known locations; on install, target the preferred one.
  const paths = action === "uninstall"
    ? [antigravityPreferred, antigravityFallback]
    : [antigravityInstallPath()];
  for (const path of paths) {
    await applyHost({
      label: "Antigravity MCP config",
      path,
      action,
      dryRun,
      read: JSON.parse,
      write: (c) => JSON.stringify(c, null, 2),
      getServers: (c) => c.mcpServers,
      setServers: (c, s) => {
        if (Object.keys(s).length === 0) delete c.mcpServers;
        else c.mcpServers = s;
      },
      entry: () => ({
        command: "node",
        args: [distEntry],
        env: { MORROWIND_ROOT: morrowindRoot },
      }),
    });
  }
}

async function handlePi(action, dryRun, morrowindRoot) {
  await applyHost({
    label: "Pi MCP config",
    path: piConfigPath(),
    action,
    dryRun,
    read: JSON.parse,
    write: (c) => JSON.stringify(c, null, 2),
    // Pi's built-in MCP (and optional adapter) read this shared Pi config.
    getServers: (c) => c.mcpServers,
    setServers: (c, s) => {
      if (Object.keys(s).length === 0) delete c.mcpServers;
      else c.mcpServers = s;
    },
    // Pi infers stdio from `command`. Timeout is in seconds: the built-in
    // default of 60s is too short for mw_wait_for_event (up to 300s).
    entry: () => ({
      command: "node",
      args: [distEntry],
      env: { MORROWIND_ROOT: morrowindRoot },
      timeout: 360,
    }),
  });
}

async function handleOpenCode(action, dryRun, morrowindRoot) {
  await applyHost({
    label: "OpenCode MCP config",
    path: openCodeConfigPath(),
    action,
    dryRun,
    // JSONC on paper; we only handle plain JSON, so a config with comments or
    // trailing commas fails the parse check above rather than being rewritten.
    read: JSON.parse,
    write: (c) => JSON.stringify(c, null, 2),
    getServers: (c) => c.mcp,
    setServers: (c, s) => {
      if (Object.keys(s).length === 0) delete c.mcp;
      else c.mcp = s;
    },
    entry: () => ({
      type: "local",
      // OpenCode takes one combined argv array, not command + args.
      command: ["node", distEntry],
      // Env key is `environment` here, not `env` as in the other hosts.
      environment: { MORROWIND_ROOT: morrowindRoot },
      enabled: true,
      // NOTE: milliseconds, unlike Cline/Codex above which count seconds.
      // OpenCode's own default is 5s, far too short for mw_wait_for_event.
      timeout: 86400000,
    }),
  });
}

async function handleFreebuff(action, dryRun, morrowindRoot) {
  await applyHost({
    label: "Freebuff MCP config",
    path: freebuffConfigPath,
    action,
    dryRun,
    read: JSON.parse,
    write: (c) => JSON.stringify(c, null, 2),
    getServers: (c) => c.mcpServers,
    setServers: (c, s) => {
      if (Object.keys(s).length === 0) delete c.mcpServers;
      else c.mcpServers = s;
    },
    // Freebuff's schema is a strict object: a stdio entry may carry only
    // type/command/args/env, and one unknown key makes it skip the *whole*
    // file, taking every other server in it down too. So no `timeout` here --
    // Freebuff applies the MCP SDK's fixed 60s request timeout, which means
    // mw_wait_for_event's default 30s wait fits, but anything over ~60s fails.
    entry: () => ({
      command: "node",
      args: [distEntry],
      env: { MORROWIND_ROOT: morrowindRoot },
    }),
  });
}

async function handleMod(action, dryRun, morrowindRoot) {
  const mwseDir = join(morrowindRoot, "Data Files", "MWSE");
  const target = join(mwseDir, "mods", "mwseMCP");
  console.log(`\n--- In-game bridge mod (${target}) ---`);

  // A junction here is a dev checkout linked into the game: copying over it
  // would write into the repo, and removing through it would delete the source.
  const stat = await lstat(target).catch(() => undefined);
  if (stat?.isSymbolicLink()) {
    console.log(`[-] Linked to a dev checkout. Leaving it alone.`);
    return;
  }

  if (action === "install") {
    if (!existsSync(join(mwseDir, "core"))) {
      console.warn(`[!] MWSE does not appear to be installed (no ${join(mwseDir, "core")}). Install MWSE 2.1 first.`);
    }
    if (dryRun) {
      console.log(`[~] DRY RUN: would copy ${modSource} -> ${target}`);
      return;
    }
    await rm(target, { recursive: true, force: true });
    await cp(modSource, target, { recursive: true });
    console.log(`[+] Copied the bridge mod.`);
  } else {
    if (!stat) {
      console.log(`[-] Not installed. Skipping.`);
      return;
    }
    if (dryRun) {
      console.log(`[~] DRY RUN: would remove ${target}`);
      return;
    }
    await rm(target, { recursive: true, force: true });
    console.log(`[+] Removed the bridge mod.`);
  }
}

async function main() {
  const { action, dryRun, explicitRoot, explicitHosts } = parseArgs(process.argv);
  const hosts = explicitHosts ?? (action === "install" ? detectedHosts() : ALL_HOSTS);

  // Uninstalling host entries alone never needs the game's location.
  const needsRoot = action === "install" || hosts.includes("mod");
  const morrowindRoot = needsRoot ? await resolveMorrowindRoot(explicitRoot) : undefined;
  if (needsRoot && !morrowindRoot) {
    console.error(
      "[x] Could not find Morrowind. Re-run with --morrowind-root \"<folder containing Morrowind.exe>\".",
    );
    process.exit(1);
  }

  console.log(`Executing ${action.toUpperCase()}${dryRun ? " (DRY RUN)" : ""} for: ${hosts.join(", ")}`);
  console.log(`  server entry: node ${distEntry}`);
  if (morrowindRoot) console.log(`  MORROWIND_ROOT: ${morrowindRoot}`);

  if (action === "install" && !existsSync(distEntry)) {
    console.warn(`\n[!] ${distEntry} does not exist yet. Run 'npm run build' before the host starts the server.`);
  }
  if (action === "install" && !existsSync(morrowindRoot)) {
    console.warn(`[!] MORROWIND_ROOT path does not exist: ${morrowindRoot}`);
  }

  if (hosts.includes("mod")) await handleMod(action, dryRun, morrowindRoot);
  if (hosts.includes("claude")) await handleClaude(action, dryRun, morrowindRoot);
  if (hosts.includes("cline")) await handleCline(action, dryRun, morrowindRoot);
  if (hosts.includes("copilot")) await handleCopilot(action, dryRun, morrowindRoot);
  if (hosts.includes("codex")) await handleCodex(action, dryRun, morrowindRoot);
  if (hosts.includes("antigravity")) await handleAntigravity(action, dryRun, morrowindRoot);
  if (hosts.includes("pi")) await handlePi(action, dryRun, morrowindRoot);
  if (hosts.includes("opencode")) await handleOpenCode(action, dryRun, morrowindRoot);
  if (hosts.includes("freebuff")) await handleFreebuff(action, dryRun, morrowindRoot);

  console.log("\nDone.");
  if (action === "install" && !dryRun) {
    console.log("Hosts point at this folder by absolute path: re-run the installer if you move it.");
    console.log("Restart your AI tools so they pick up the new server.");
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
