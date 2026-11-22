/**
 * Unit tests for iCloud shared-link availability detection.
 *
 * iCloud renders a "Shared photos not available" page for expired, revoked, or
 * invalid links. Without detection, giil's screenshot fallback saved that page
 * and reported success (exit 0). The resolver payloads below are the actual
 * records/resolve responses returned for an expired share and for an invalid
 * short GUID.
 */

import { describe, it, before, after } from 'node:test';
import assert from 'node:assert';
import { writeFileSync, unlinkSync, existsSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';
import { execSync } from 'child_process';

const __dirname = dirname(fileURLToPath(import.meta.url));

describe('iCloud Share Status Tests', () => {
    let mod;
    let tempModule;

    before(async () => {
        const extractorPath = join(__dirname, 'extract-functions.mjs');
        const projectRoot = join(__dirname, '../..');
        tempModule = join(projectRoot, `giil-test-icloud-share-status-${process.pid}.mjs`);
        const extracted = execSync(`node "${extractorPath}"`, { encoding: 'utf8' });
        writeFileSync(tempModule, extracted);
        mod = await import(tempModule);
    });

    after(() => {
        if (tempModule && existsSync(tempModule)) {
            try { unlinkSync(tempModule); } catch {}
        }
    });

    describe('classifyIcloudResolveResponse', () => {
        it('is extracted from the embedded extractor', () => {
            assert.strictEqual(typeof mod.classifyIcloudResolveResponse, 'function');
        });

        it('maps an expired share (Share not found) to NOT_FOUND exit 12', () => {
            const payload = {
                results: [{
                    shortGUID: { value: '02cD9okNHvVd-uuDnPCH3ZEEA', shouldFetchRootRecord: true },
                    reason: 'Share not found',
                    serverErrorCode: 'NOT_FOUND',
                    minimallyResolved: false,
                    requireAppleLogin: false
                }]
            };
            const status = mod.classifyIcloudResolveResponse(payload);
            assert.ok(status);
            assert.strictEqual(status.code, 'NOT_FOUND');
            assert.strictEqual(status.exitCode, mod.ExitCodes.NOT_FOUND);
            assert.strictEqual(status.exitCode, 12);
            assert.strictEqual(status.serverErrorCode, 'NOT_FOUND');
            assert.strictEqual(status.reason, 'Share not found');
            assert.match(status.message, /not found/i);
        });

        it('maps an invalid short GUID to NOT_FOUND exit 12', () => {
            const payload = {
                results: [{
                    shortGUID: { value: 'NONEXISTENT_LINK_ABC123XYZ', shouldFetchRootRecord: true },
                    reason: 'Cannot resolve shortGUID',
                    serverErrorCode: 'NOT_FOUND',
                    minimallyResolved: false,
                    requireAppleLogin: false
                }]
            };
            const status = mod.classifyIcloudResolveResponse(payload);
            assert.strictEqual(status.code, 'NOT_FOUND');
            assert.strictEqual(status.exitCode, 12);
        });

        it('maps sign-in or permission failures to AUTH_REQUIRED exit 11', () => {
            for (const result of [
                { serverErrorCode: 'ACCESS_DENIED', reason: 'Access denied' },
                { serverErrorCode: 'AUTHENTICATION_REQUIRED' },
                { serverErrorCode: 'NOT_FOUND', requireAppleLogin: true }
            ]) {
                const status = mod.classifyIcloudResolveResponse({ results: [result] });
                assert.strictEqual(status.code, 'AUTH_REQUIRED', JSON.stringify(result));
                assert.strictEqual(status.exitCode, 11);
            }
        });

        it('returns null when the share resolved', () => {
            const payload = {
                results: [{
                    shortGUID: { value: 'ABC', shouldFetchRootRecord: true },
                    rootRecordName: 'X',
                    zoneID: { zoneName: 'Y' },
                    minimallyResolved: true
                }]
            };
            assert.strictEqual(mod.classifyIcloudResolveResponse(payload), null);
        });

        it('returns null when any requested share resolved', () => {
            const payload = { results: [{ serverErrorCode: 'NOT_FOUND' }, { rootRecordName: 'X' }] };
            assert.strictEqual(mod.classifyIcloudResolveResponse(payload), null);
        });

        it('returns null for transient or unknown server errors (no false NOT_FOUND)', () => {
            for (const code of ['THROTTLED', 'INTERNAL_ERROR', 'SERVICE_UNAVAILABLE', 'TRY_AGAIN_LATER']) {
                assert.strictEqual(mod.classifyIcloudResolveResponse({ results: [{ serverErrorCode: code }] }), null, code);
            }
        });

        it('returns null for empty, malformed, or non-resolver payloads', () => {
            for (const payload of [null, undefined, {}, { results: [] }, { results: 'x' }, 'text', 42]) {
                assert.strictEqual(mod.classifyIcloudResolveResponse(payload), null, JSON.stringify(payload));
            }
        });
    });

    describe('iCloud URL filters', () => {
        it('recognizes only the public share resolver endpoint', () => {
            const re = mod.ICLOUD_SHARE_RESOLVE_RE;
            assert.ok(re.test('https://ckdatabasews.icloud.com/database/1/com.apple.photos.cloud/production/public/records/resolve?remapEnums=true&getCurrentSyncToken=true'));
            assert.ok(!re.test('https://ckdatabasews.icloud.com/database/1/com.apple.photos.cloud/production/public/records/query?x=1'));
            assert.ok(!re.test('https://evil.example/ckdatabasews.icloud.com/database/1/com.apple.photos.cloud/production/public/records/resolve'));
        });

        it('treats iCloud web-app chrome as non-content but keeps the content CDN', () => {
            const re = mod.ICLOUD_APP_ASSET_RE;
            assert.ok(re.test('https://www.icloud.com/applications/photos3/2642Build18/test_images/orientation_test_image.jpeg?&og=Resource%20Download'));
            assert.ok(re.test('https://www.icloud.com/applications/photos3/2642Build18/logos/icloudLogo.svg'));
            assert.ok(re.test('https://www.icloud.com/system/icloud.com/current/wallpaper.svg'));
            assert.ok(!re.test('https://cvws.icloud-content.com/B/AbCdEf/IMG_0001.JPG?o=x'));
            assert.ok(!re.test('https://www.icloud.com/photos/#02cD9okNHvVd-uuDnPCH3ZEEA'));
        });
    });
});
