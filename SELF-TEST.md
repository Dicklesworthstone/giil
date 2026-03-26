# SELF-TEST: giil

Run from the skill directory.

## 1) Reference files exist
```bash
test -f references/COMMANDS.md
test -f references/CAPTURE-STRATEGY.md
test -f references/TROUBLESHOOTING.md
```

## 2) Tool availability + version
```bash
command -v giil
giil --version || giil -V
```

## 3) Help output sanity
```bash
giil --help | head -n 40
```

## 4) Output mode smoke (safe, expect error on invalid URL)
```bash
giil "https://dropbox.com/s/example/test.jpg" --print-url --timeout 5 || true
```

Expected:
- `giil` is installed or the install command is surfaced.
- `--help` prints options matching references/COMMANDS.md.
- `--print-url` returns either a CDN URL or a clear error message.
