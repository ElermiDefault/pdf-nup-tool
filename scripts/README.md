# Scripts

## `package_macos.sh`

Creates a clean macOS local app packaging preview zip under `dist/`.

```bash
./scripts/package_macos.sh v0.4.1
```

The package excludes Git metadata, Node dependencies, runtime cache, generated PDFs, and local sample PDFs. It includes the built frontend static files.

## `install_macos.sh`

Creates a local `.venv`, installs backend dependencies, builds frontend static files, and can install a `pdfnuptool` command into `~/.local/bin`.
