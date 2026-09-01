/*
 * Copyright (c) 2026, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

import { createElement } from 'lwc';
import InlineStatus from 'c/inlineStatus';

async function flushPromises() {
    await Promise.resolve();
    await Promise.resolve();
}

function createStatus(props = {}) {
    const element = createElement('c-inline-status', { is: InlineStatus });
    Object.keys(props).forEach((key) => {
        element[key] = props[key];
    });
    document.body.appendChild(element);
    return element;
}

describe('c-inline-status', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders nothing when message is empty', () => {
        const element = createStatus({ variant: 'info', message: '' });
        expect(element.shadowRoot.querySelector('[role="status"]')).toBeNull();
        expect(element.shadowRoot.querySelector('[role="alert"]')).toBeNull();
        expect(element.shadowRoot.textContent.trim()).toBe('');
    });

    it('renders an info status region with the message', () => {
        const element = createStatus({ variant: 'info', message: 'Saved locally.' });
        const region = element.shadowRoot.querySelector('[role="status"]');
        expect(region).not.toBeNull();
        expect(region.textContent).toContain('Saved locally.');
        expect(element.shadowRoot.querySelector('lightning-icon')).not.toBeNull();
    });

    it('renders an error as an alert', () => {
        const element = createStatus({ variant: 'error', message: 'Create failed.' });
        const region = element.shadowRoot.querySelector('[role="alert"]');
        expect(region).not.toBeNull();
        expect(region.textContent).toContain('Create failed.');
        expect(element.shadowRoot.querySelector('[role="status"]')).toBeNull();
    });

    it('renders a success status region', () => {
        const element = createStatus({ variant: 'success', message: 'Record created.' });
        const region = element.shadowRoot.querySelector('[role="status"]');
        expect(region).not.toBeNull();
        expect(region.textContent).toContain('Record created.');
    });

    it('treats an unknown variant as info', () => {
        const element = createStatus({ variant: 'warning', message: 'Heads up.' });
        expect(element.shadowRoot.querySelector('[role="status"]')).not.toBeNull();
        expect(element.shadowRoot.querySelector('[role="alert"]')).toBeNull();
        expect(element.shadowRoot.textContent).toContain('Heads up.');
    });

    it('hides the region when the message is cleared', async () => {
        const element = createStatus({ variant: 'success', message: 'Created.' });
        expect(element.shadowRoot.querySelector('[role="status"]')).not.toBeNull();

        element.message = '   ';
        await flushPromises();

        expect(element.shadowRoot.querySelector('[role="status"]')).toBeNull();
    });
});
