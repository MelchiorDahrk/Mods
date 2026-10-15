"""Compatibility entry point; the shader validator now covers both engines."""
from runpy import run_module

if __name__ == '__main__':
    run_module('validate_shaders', run_name='__main__')
