# Scripts

## `package_macos.sh`

Creates a clean macOS app preview zip under `dist/`.

```bash
./scripts/package_macos.sh v0.5.0
```

The package excludes Git metadata, Node dependencies, runtime cache, generated PDFs, and local sample PDFs. It includes the built frontend static files and `PDF N-up Tool.app`.

## `build_macos_app.sh`

Builds `PDF N-up Tool.app` with the project icon and a wrapper executable that launches `pdfnuptool`.

## `install_macos.sh`

Creates a local `.venv`, installs backend dependencies, builds frontend static files, and can install a `pdfnuptool` command into `~/.local/bin`.
