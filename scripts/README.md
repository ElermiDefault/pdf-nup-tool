# Scripts

## `build_dmg.sh`

Creates a macOS DMG release package under `dist/`.

```bash
python -m pip install pyinstaller
./scripts/build_dmg.sh v1.0.0
```

The DMG contains `PDF N-up Tool.app`, an `Applications` shortcut, `README.md`, and `LICENSE`.

## `build_native_dmg.sh`

Creates a Swift + WKWebView native shell DMG under `dist/`.

```bash
python -m pip install pyinstaller
./scripts/build_native_dmg.sh v1.1.0
```

The DMG contains a macOS app window shell, the bundled PyInstaller backend runtime, an `Applications` shortcut, `README.md`, and `LICENSE`.

The native shell defaults to `MACOSX_DEPLOYMENT_TARGET=11.0` for Apple Silicon builds. Override that environment variable before running the script if a different macOS deployment target is required.

## `build_native_app.sh`

Creates the Swift + WKWebView native shell app package under `dist/`.

```bash
./scripts/build_native_app.sh v1.1.0
```

## `build_pyinstaller_backend.sh`

Creates the PyInstaller backend runtime used by the native shell.

```bash
./scripts/build_pyinstaller_backend.sh v1.1.0
```

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
