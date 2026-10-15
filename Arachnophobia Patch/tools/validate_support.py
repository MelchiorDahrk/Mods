"""Validate SSS modules and both self-contained FOMOD packages.

Development dependencies: PyYAML and jsonschema. No game files are modified.
Pass --schema to also check a downloaded SSS build's schema.
Pass --archives to also verify and test the extracted release archives.
"""

import argparse
import itertools
import json
from pathlib import Path
import tempfile
import xml.etree.ElementTree as ET
import zipfile

import jsonschema
import yaml

from build_release import ENGINES, archive_path, release_files


ROOT = Path(__file__).resolve().parents[1]
PACKAGES = {
    "vanilla": "03 Vanilla Spider Centurions Replacements",
    "oaab": "01 OAAB_Data Creature Replacements",
    "tamriel": "02 Tamriel_Data Creature Replacements",
}
MESH_FOLDERS = {"vanilla": ("r",), "oaab": ("oaab",), "tamriel": ("tr", "sky")}


class UniqueKeysLoader(yaml.SafeLoader):
    """Reject duplicate YAML keys instead of silently dropping a rule value."""


def unique_mapping(loader, node):
    result = {}
    for key_node, value_node in node.value:
        key = loader.construct_object(key_node)
        if key in result:
            raise ValueError(f"Duplicate YAML key: {key}")
        result[key] = loader.construct_object(value_node)
    return result


UniqueKeysLoader.add_constructor(
    yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, unique_mapping
)


def validate_modules(schemas):
    counts = {"vanilla": 1, "oaab": 5, "tamriel": 9}
    seen = set()
    for flag, package in PACKAGES.items():
        files = list((ROOT / "OpenMW" / package / "scripts/staticSwitcher/data").glob("*.yaml"))
        assert len(files) == 1, f"Expected one module for {package}"
        module = yaml.load(files[0].read_text(encoding="utf-8"), Loader=UniqueKeysLoader)
        for schema in schemas:
            jsonschema.Draft7Validator.check_schema(schema)
            jsonschema.validate(module, schema)
        assert len(module["instances"]) == counts[flag]
        for rule in module["instances"]:
            conditions = {key: value for item in rule["conditions"] for key, value in item.items()}
            assert conditions["object_type"] == "Creature"
            assert conditions["is_dead"] is False
            assert conditions["is_respawning"] is False
            pattern = conditions["record_id"]
            assert pattern.startswith("^") and pattern.endswith("$")
            record_id = pattern[1:-1]
            assert record_id == record_id.lower() and record_id not in seen
            seen.add(record_id)
            assert rule["once"] is True and len(rule["actions"]) == 1
            action = rule["actions"][0]
            assert set(action) == {"replace"} and len(action["replace"]) == 1
            assert next(iter(action["replace"].values())) == 1
        print(f"PASS {files[0].name}: {counts[flag]} rules, {len(schemas)} schemas")
    assert "t_dae_cre_spiderdae_02" not in seen
    assert "ab_fau_spiderparasol" not in seen
    assert "centurion_spider_tga1" not in seen
    assert "centurion_spider_tga2" not in seen
    assert "centurion_spider_nchur" not in seen


def relative_path(value):
    normalized = value.replace("\\", "/")
    path = Path(normalized)
    assert normalized and not path.is_absolute() and not path.drive
    assert ".." not in path.parts, f"Path escapes package: {value}"
    return path


def add_files(package_root, manifest, elements):
    for element in elements:
        source = package_root / relative_path(element.attrib["source"])
        destination = relative_path(element.attrib["destination"])
        assert source.exists(), f"Missing installer source: {source}"
        entries = [(source, destination)]
        if element.tag == "folder":
            assert source.is_dir()
            entries = [(file, destination / file.relative_to(source)) for file in source.rglob("*") if file.is_file()]
        for file, target in entries:
            key = target.as_posix().lower()
            assert key not in manifest or manifest[key] == file, f"Conflicting install destination: {target}"
            manifest[key] = file


def validate_installer(engine, package_root):
    visuals = package_root / "00 Visual Replacements"
    config = ET.parse(package_root / "fomod/ModuleConfig.xml").getroot()
    assert config.findtext("moduleName") == f"Arachnophobia Patch - {engine}"
    assert (package_root / relative_path(config.find("moduleImage").attrib["path"])).is_file()
    assert not config.findall(".//group[@name='Engine']"), "Engine is fixed by the package"
    modes = config.findall(".//group[@name='Runtime']/plugins/plugin")
    webs = config.findall(".//group[@name='Webs']/plugins/plugin")
    creatures = config.findall(".//installStep[@name='Creature Replacements']//plugins/plugin")
    assert len(modes) == 2 and len(webs) == 2 and len(creatures) == 3
    assert [plugin.findtext("conditionFlags/flag[@name='runtime']") for plugin in modes] == ["On", None]
    assert [plugin.find("conditionFlags/flag").attrib["name"] for plugin in creatures] == list(PACKAGES)
    combinations = 0
    for mode, web, choices in itertools.product(modes, webs, itertools.product([False, True], repeat=3)):
        selected = [mode, web] + [plugin for plugin, enabled in zip(creatures, choices) if enabled]
        flags = {flag.attrib["name"]: flag.text for plugin in selected for flag in plugin.findall("conditionFlags/flag")}
        manifest = {}
        add_files(package_root, manifest, config.findall("requiredInstallFiles/*"))
        for plugin in selected:
            add_files(package_root, manifest, plugin.findall("files/*"))
        for pattern in config.findall("conditionalFileInstalls/patterns/pattern"):
            dependencies = pattern.find("dependencies")
            assert dependencies.attrib.get("operator", "And") == "And"
            assert all(item.tag == "flagDependency" for item in dependencies)
            if all(flags.get(item.attrib["flag"]) == item.attrib["value"] for item in dependencies):
                add_files(package_root, manifest, pattern.findall("files/*"))
        expected = {"arachnophobia patch.txt"}
        if web.find("files") is not None and len(web.find("files")):
            expected.update("textures/" + file.relative_to(visuals / "Textures").as_posix().lower()
                            for file in (visuals / "Textures").rglob("*") if file.is_file())
        for flag, package in PACKAGES.items():
            if flags.get(flag) != "On":
                continue
            for mesh_folder in MESH_FOLDERS[flag]:
                expected.update("meshes/" + file.relative_to(visuals / "Meshes").as_posix().lower()
                                for file in (visuals / "Meshes" / mesh_folder).rglob("*") if file.is_file())
            if flag == "oaab":
                expected.add("arachnophobiapatch_oaab.esp")
            if flags.get("runtime") == "On":
                directory = package_root / package
                expected.update(file.relative_to(directory).as_posix().lower()
                                for file in directory.rglob("*") if file.is_file())
        assert set(manifest) == expected, (engine, mode.attrib["name"], choices, set(manifest) ^ expected)
        assert not any("_reference" in file.as_posix().lower() for file in manifest.values())
        combinations += 1
    assert combinations == 32
    print(f"PASS {engine} FOMOD: all {combinations} runtime/web/creature combinations")


def validate_package_contents():
    visual_sets = []
    for engine in ENGINES:
        package_root = ROOT / engine
        files = list(release_files(package_root))
        relative = [file.relative_to(package_root).as_posix().lower() for file in files]
        assert len(relative) == len(set(relative)), "Case-insensitive archive path collision"
        forbidden = "mwse" if engine == "OpenMW" else "scripts"
        assert not any(forbidden in path.split("/") for path in relative), f"Wrong engine files in {engine}"
        visuals = package_root / "00 Visual Replacements"
        assets = {file.relative_to(visuals).as_posix(): file.read_bytes()
                  for file in visuals.rglob("*") if file.is_file()}
        assert len(assets) == 30, f"Missing visual replacements in {engine}"
        visual_sets.append(assets)
    assert visual_sets[0] == visual_sets[1], "Visual replacements differ between packages"
    oaab_plugins = [ROOT / engine / PACKAGES["oaab"] / "ArachnophobiaPatch_OAAB.ESP" for engine in ENGINES]
    assert oaab_plugins[0].read_bytes() == oaab_plugins[1].read_bytes(), "OAAB patches differ between engines"
    print("PASS self-contained packages: 30 identical visual assets and OAAB patch in each; engine files isolated")


def validate_archives():
    cache = ROOT / ".validation-cache"
    cache.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="release-check-", dir=cache) as temporary:
        for engine in ENGINES:
            package_root = ROOT / engine
            expected = {file.relative_to(package_root).as_posix(): file for file in release_files(package_root)}
            with zipfile.ZipFile(archive_path(engine)) as archive:
                assert archive.testzip() is None, f"Corrupt {engine} archive"
                assert len(archive.namelist()) == len(expected) and set(archive.namelist()) == set(expected)
                for name, file in expected.items():
                    relative_path(name)
                    assert archive.read(name) == file.read_bytes(), f"Archive differs: {name}"
                extracted = Path(temporary) / engine
                archive.extractall(extracted)
            validate_installer(engine, extracted)
            print(f"PASS {engine} archive: exact package contents and standalone installer")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--schema", action="append", type=Path, default=[])
    parser.add_argument("--archives", action="store_true")
    args = parser.parse_args()
    paths = [ROOT / "_Reference/Static Switching System (OpenMW)/Scripts/staticSwitcher/schema/replacerSchema.json", *args.schema]
    validate_modules([json.loads(path.read_text(encoding="utf-8")) for path in paths])
    validate_package_contents()
    for engine in ENGINES:
        validate_installer(engine, ROOT / engine)
    if args.archives:
        validate_archives()


if __name__ == "__main__":
    main()
