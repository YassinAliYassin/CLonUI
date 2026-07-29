/**
 * @license
 * Copyright 2025 CLonUI (github.com/SolidAI/CLonUI)
 * SPDX-License-Identifier: Apache-2.0
 */

import { getPlatformServices } from '@/common/platform';

/**
 * Returns baseName unchanged in release builds, or baseName + '-dev' in dev builds.
 * When CLONUI_MULTI_INSTANCE=1, appends '-2' to isolate the second dev instance.
 * Used to isolate symlink and directory names between environments.
 *
 * @example
 * getEnvAwareName('.clonui')        // release → '.clonui',        dev → '.clonui-dev'
 * getEnvAwareName('.clonui-config') // release → '.clonui-config', dev → '.clonui-config-dev'
 * // with CLONUI_MULTI_INSTANCE=1:  dev → '.clonui-dev-2'
 */
export function getEnvAwareName(baseName: string): string {
  if (getPlatformServices().paths.isPackaged() === true) return baseName;
  const suffix = process.env.CLONUI_MULTI_INSTANCE === '1' ? '-dev-2' : '-dev';
  return `${baseName}${suffix}`;
}
