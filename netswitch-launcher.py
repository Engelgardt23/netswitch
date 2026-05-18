"""
PyInstaller entry point — sits at the repo root and uses an *absolute* import
so the bundled exe doesn't need relative-import resolution at runtime.

For dev work without an install use `python -m netswitch` instead.
"""

from netswitch.app import main


if __name__ == "__main__":
    main()
