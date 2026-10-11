# mwse-mcp

Lets an AI coding agent (Claude Code, Codex, Cline, GitHub Copilot CLI, Antigravity,
Pi, OpenCode, Freebuff) talk to a **running** Morrowind: run Lua in the game,
read live state, react to events, and write mods/shaders.

> ⚠️ Not a sandbox. The agent's Lua runs for real in your game. Use a throwaway
> save, and keep backups of saves you care about.

## You need

- Morrowind with an **up-to-date MWSE 2.1** (run MWSE-Update.exe). MGE XE is
  optional; it's only needed for shader work.
- [Node.js](https://nodejs.org/) 18 or newer (with npm), and an internet
  connection the first time you install.
- At least one of the AI tools above, already installed and run once.

## Install

1. Unzip this folder somewhere **permanent** (e.g. `Documents\mwse-mcp`). Your AI
   tools point at it by absolute path, so if you move it later, run the installer again.
   When updating to a newer zip, replace the whole folder rather than unzipping over it.
2. Double-click `install.bat`. It will:
   - download its dependencies with npm (first run only);
   - find Morrowind (from the registry, or ask you for the folder with `Morrowind.exe`);
   - copy the in-game bridge mod to `Data Files\MWSE\mods\mwseMCP`;
   - register the server with every supported AI tool it finds on this PC
     (each config is backed up to `.bak` first).
3. Restart your AI tool(s).
4. Launch Morrowind and load a save. Then ask your agent to call
   `mw_usage_guide`, then try:
   *"Use mw_eval_lua to show a message box in the game."*

To install into a specific location or tool:
`install.bat --morrowind-root "D:\Games\Morrowind" --host mod,claude`

## Uninstall

Double-click `uninstall.bat`. It removes the server from every AI tool's config,
and removes the bridge mod from the game.

## Troubleshooting

- **"bridge not connected" / connection refused**: the game isn't running, or
  hasn't finished loading. Check `MWSE.log` in the Morrowind folder for a
  `[mwseMCP] listening on 127.0.0.1:31415` line.
- **Windows blocks `install.bat`**: right-click the zip → Properties → *Unblock*,
  then unzip again.
- **Something else uses port 31415**: set `BRIDGE_PORT` in the AI tool's server
  config, and change `port` at the top of `Data Files\MWSE\mods\mwseMCP\main.lua`
  to match.
- **Agent writes go nowhere you expected**: by design, the agent can only write to
  `Data Files\MWSE\mods\AgentGenerated\` and
  `Data Files\shaders\XEshaders\AgentGenerated\`.
