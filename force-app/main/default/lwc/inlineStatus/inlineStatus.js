/*
 * Copyright (c) 2026, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

import { LightningElement, api } from 'lwc';

const ICONS = {
    success: 'utility:success',
    error: 'utility:error',
    info: 'utility:info'
};

const ASSISTIVE = {
    success: 'Success',
    error: 'Error',
    info: 'Information'
};

/**
 * Inline status region for Experience Cloud. Prefer this over ShowToastEvent,
 * which is not reliable on LWR guest pages.
 */
export default class InlineStatus extends LightningElement {
    /**
     * Visual and ARIA variant: success | error | info.
     * @type {string}
     */
    @api variant = 'info';

    /**
     * Message to display. The region is omitted when this is empty.
     * @type {string}
     */
    @api message;

    get hasMessage() {
        return typeof this.message === 'string' && this.message.trim().length > 0;
    }

    get normalizedVariant() {
        const value = (this.variant || 'info').toString().toLowerCase();
        if (value === 'success' || value === 'error' || value === 'info') {
            return value;
        }
        return 'info';
    }

    get notificationClass() {
        const theme =
            this.normalizedVariant === 'error'
                ? 'slds-theme_error'
                : this.normalizedVariant === 'success'
                  ? 'slds-theme_success'
                  : 'slds-theme_info';
        return `slds-scoped-notification slds-media slds-media_center ${theme}`;
    }

    get alertRole() {
        return this.normalizedVariant === 'error' ? 'alert' : 'status';
    }

    get iconName() {
        return ICONS[this.normalizedVariant];
    }

    get assistiveText() {
        return ASSISTIVE[this.normalizedVariant];
    }
}
