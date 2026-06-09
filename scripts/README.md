# Scripts

## `package_macos.sh`

Creates a clean macOS source preview zip under `dist/`.

```bash
./scripts/package_macos.sh v0.2.0
```

The package excludes Git metadata, Node dependencies, build output, runtime cache, generated PDFs, and local sample PDFs.

