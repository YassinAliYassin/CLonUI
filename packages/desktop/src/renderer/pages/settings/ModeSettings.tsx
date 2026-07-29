/**
 * @license
 * Copyright 2025 CLonUI (github.com/SolidAI/CLonUI)
 * SPDX-License-Identifier: Apache-2.0
 */

import React from 'react';
import ModelModalContent from '@/renderer/components/settings/SettingsModal/contents/ModelModalContent';
import SettingsPageWrapper from './components/SettingsPageWrapper';

const ModeSettings: React.FC = () => {
  return (
    <SettingsPageWrapper contentClassName='max-w-1100px'>
      <ModelModalContent />
    </SettingsPageWrapper>
  );
};

export default ModeSettings;
