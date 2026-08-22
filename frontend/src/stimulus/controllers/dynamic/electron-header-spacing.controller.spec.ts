//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

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
