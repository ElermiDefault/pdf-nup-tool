# Scripts

## `package_macos.sh`

Creates a clean macOS semi-automatic installer zip under `dist/`.

```bash
./scripts/package_macos.sh v0.3.0
```

The package excludes Git metadata, Node dependencies, build output, runtime cache, generated PDFs, and local sample PDFs.

## `install_macos.sh`

Creates a local `.venv`, installs backend and frontend dependencies, and can install a `pdfnuptool` command into `~/.local/bin`.
