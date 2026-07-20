import { describe, expect, it } from 'vitest';
import { isElectronUserAgent } from './electron-header-spacing.controller';

describe('ElectronHeaderSpacingController', () => {
  it('detects Electron user agents', () => {
    expect(isElectronUserAgent('Mozilla/5.0 Electron/39.0.0')).toBe(true);
  });

  it.each([
    'Mozilla/5.0 Electron/39.0.0 wxwork/2.1.3',
    'Mozilla/5.0 Electron/39.0.0 MicroMessenger/6.2',
  ])('excludes WxWork user agents containing Electron: %s', (userAgent) => {
    expect(isElectronUserAgent(userAgent)).toBe(false);
  });
});
