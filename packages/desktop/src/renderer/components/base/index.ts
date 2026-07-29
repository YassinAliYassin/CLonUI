/**
 * @license
 * Copyright 2025 CLonUI (github.com/SolidAI/CLonUI)
 * SPDX-License-Identifier: Apache-2.0
 */

/**
 * CLonUI 基础组件库统一导出 / CLonUI base components unified exports
 *
 * 提供所有基础组件和类型的统一导出入口
 * Provides unified export entry for all base components and types
 */

// ==================== 组件导出 / Component Exports ====================

export { default as CLonModal } from './CLonModal';
export { default as CLonCollapse } from './CLonCollapse';
export { default as CLonSelect } from './CLonSelect';
export { default as CLonScrollArea } from './CLonScrollArea';
export { default as CLonSteps } from './CLonSteps';
export { default as CLonSearchInput } from './CLonSearchInput';
export { default as CLonInlineSearchInput } from './CLonInlineSearchInput';

// ==================== 类型导出 / Type Exports ====================

// CLonModal 类型 / CLonModal types
export type {
  ModalSize,
  ModalHeaderConfig,
  ModalFooterConfig,
  ModalContentStyleConfig,
  CLonModalProps,
} from './CLonModal';
export { MODAL_SIZES } from './CLonModal';

// CLonCollapse 类型 / CLonCollapse types
export type { CLonCollapseProps, CLonCollapseItemProps } from './CLonCollapse';

// CLonSelect 类型 / CLonSelect types
export type { CLonSelectProps } from './CLonSelect';

// CLonSteps 类型 / CLonSteps types
export type { CLonStepsProps } from './CLonSteps';

// CLonSearchInput 类型 / CLonSearchInput types
export type { CLonSearchInputProps } from './CLonSearchInput';

// CLonInlineSearchInput 类型 / CLonInlineSearchInput types
export type { CLonInlineSearchInputProps } from './CLonInlineSearchInput';
