# Test Fixtures

This directory contains test fixtures for the giil test suite.

## Structure

```
fixtures/
├── images/                    # Sample image files for testing
│   ├── sample-jpeg-with-exif.jpg   # JPEG with EXIF datetime
│   ├── sample-png.png              # Basic PNG
│   └── sample-webp.webp            # WebP format
├── magic-bytes/               # Binary headers for magic byte tests
│   ├── jpeg-magic.bin         # FF D8 FF (JPEG start)
│   ├── png-magic.bin          # 89 50 4E 47 0D 0A 1A 0A
│   ├── html-magic.bin         # <!DOCTYPE html>
│   └── heic-magic.bin         # ftyp heic header
└── expected-hashes/           # SHA256 checksums for E2E validation
    ├── icloud.sha256          # Expected hash for iCloud test image
    ├── dropbox.sha256         # Expected hash for Dropbox test
    └── google-photos.sha256   # Expected hash for Google Photos
```

## Image Fixtures

Sample images should be:
- Minimal file size (for fast tests)
- Real, valid image files (not mocks)
- Include necessary metadata (EXIF for datetime tests)

## Magic Byte Fixtures

Binary files containing just the magic bytes for format detection tests.
Generated programmatically to ensure exact byte sequences.

## Expected Hashes

SHA256 checksums of known good outputs from E2E tests.
Used to verify that the capture process produces consistent results.
