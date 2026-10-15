"""Build both engine shaders and package the original transparent dust texture."""
import argparse
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent.parent


def build(check=False):
    source = ROOT / "shaders"
    core = (source / "dust.glsl").read_text()
    hlsl = core
    for glsl, replacement in (("vec2", "float2"), ("vec3", "float3"), ("vec4", "float4"),
                              ("fract", "frac"), ("mix", "lerp")):
        hlsl = re.sub(r"\b" + glsl + r"\b", replacement, hlsl)
    outputs = {
        "00 OpenMW/Shaders/UntoDust.omwfx": ("openmw.omwfx.in", core),
        "00 MWSE/shaders/XEshaders/UntoDust.fx": ("mwse.fx.in", hlsl),
    }
    for name, (template, implementation) in outputs.items():
        content = (source / template).read_text().replace("@CORE@", implementation)
        path = ROOT / name
        if check:
            if not path.exists() or path.read_text() != content:
                raise RuntimeError(f"Shader needs rebuilding: {name}")
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8", newline="\n")
        print(f"{'Checked' if check else 'Built'} {name}")
    texture = (ROOT / "legacy/00 MWSE/Textures/dust/tx_alpha_dust000.dds").read_bytes()
    for folder in ("00 OpenMW", "00 MWSE"):
        path = ROOT / folder / "Textures/UntoDust/dust.dds"
        if check:
            if not path.exists() or path.read_bytes() != texture:
                raise RuntimeError(f"Dust texture needs rebuilding: {path.relative_to(ROOT)}")
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(texture)
        print(f"{'Checked' if check else 'Packaged'} {path.relative_to(ROOT)}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    build(parser.parse_args().check)
