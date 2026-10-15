"""Build separate, self-contained OpenMW and MWSE release archives."""

import argparse
from pathlib import Path
import xml.etree.ElementTree as ET
import zipfile


ROOT = Path(__file__).resolve().parents[1]
ENGINES = ("OpenMW", "MWSE")
COMPONENTS = (
    "01 OAAB_Data Creature Replacements",
    "02 Tamriel_Data Creature Replacements",
    "03 Vanilla Spider Centurions Replacements",
)
RELEASE_FOLDERS = ("00 Visual Replacements", *COMPONENTS, "fomod")
README = "Arachnophobia Patch.txt"


def release_files(package_root):
    readme = package_root / README
    if not readme.is_file():
        raise FileNotFoundError(f"Missing package readme: {readme}")
    yield readme
    for folder in RELEASE_FOLDERS:
        directory = package_root / folder
        if not directory.is_dir():
            raise FileNotFoundError(f"Missing release component: {directory}")
        yield from sorted(file for file in directory.rglob("*") if file.is_file())


def archive_path(engine):
    version = ET.parse(ROOT / engine / "fomod/info.xml").findtext("Version")
    if not version or any(char not in "0123456789.-" for char in version):
        raise ValueError(f"Invalid release version for {engine}: {version!r}")
    return ROOT / "dist" / f"Arachnophobia Patch-{engine}-{version}.zip"


def build_release(engine):
    package_root = ROOT / engine
    files = list(release_files(package_root))
    destination = archive_path(engine)
    destination.parent.mkdir(exist_ok=True)
    with zipfile.ZipFile(destination, "w", zipfile.ZIP_DEFLATED) as archive:
        for file in files:
            archive.write(file, file.relative_to(package_root).as_posix())
    return destination


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--engine", choices=ENGINES, help="Build only this engine (default: both).")
    args = parser.parse_args()
    for engine in (args.engine,) if args.engine else ENGINES:
        print(build_release(engine))


if __name__ == "__main__":
    main()
