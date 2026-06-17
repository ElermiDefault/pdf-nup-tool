# Scripts

## `build_dmg.sh`

Creates a macOS DMG release package under `dist/`.

```bash
python -m pip install pyinstaller
./scripts/build_dmg.sh v1.0.0
```

The DMG contains `PDF N-up Tool.app`, an `Applications` shortcut, `README.md`, and `LICENSE`.

## `package_macos.sh`

Creates the older source-wrapper macOS app preview zip under `dist/`.

```bash
./scripts/package_macos.sh v0.5.0
```

The package excludes Git metadata, Node dependencies, runtime cache, generated PDFs, and local sample PDFs. It includes the built frontend static files and `PDF N-up Tool.app`.

## `build_pyinstaller_app.sh`

Creates a self-contained macOS app preview zip under `dist/`.

```bash
python -m pip install pyinstaller
./scripts/build_pyinstaller_app.sh v0.6.0
```

The package contains `PDF N-up Tool.app` and does not require users to install Python, Node.js, npm, or a project-local `.venv`.

## `build_macos_app.sh`

Builds the source-wrapper `PDF N-up Tool.app` with the project icon and a wrapper executable that launches `pdfnuptool`.

## `install_macos.sh`

Creates a local `.venv`, installs backend dependencies, builds frontend static files, and can install a `pdfnuptool` command into `~/.local/bin`.
