/*
 * Copyright (c) 2026, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

import { createElement } from 'lwc';
import RecordTypeahead from 'c/recordTypeahead';

const RESULTS = [
    { id: 'a01', label: 'Alpha Vehicle' },
    { id: 'a02', label: 'Beta Vehicle' }
];

async function flushPromises() {
    await Promise.resolve();
    await Promise.resolve();
}

function createTypeahead(props = {}) {
    const element = createElement('c-record-typeahead', { is: RecordTypeahead });
    Object.keys(props).forEach((key) => {
        element[key] = props[key];
    });
    document.body.appendChild(element);
    return element;
}

function getCombobox(element) {
    return element.shadowRoot.querySelector('[role="combobox"]');
}

async function typeTerm(element, term) {
    const input = getCombobox(element);
    input.value = term;
    input.dispatchEvent(new Event('input', { bubbles: true }));
    await flushPromises();
    return input;
}

describe('c-record-typeahead', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('renders a labeled combobox and listbox', () => {
        const element = createTypeahead({
            label: 'Vehicle asset',
            placeholder: 'Type to search'
        });

        const input = getCombobox(element);
        expect(input).not.toBeNull();
        expect(input.getAttribute('placeholder')).toBe('Type to search');
        expect(element.shadowRoot.querySelector('[role="listbox"]')).not.toBeNull();
        expect(element.shadowRoot.textContent).toContain('Vehicle asset');
    });

    it('does not fire search until the term meets minLength, and shows a hint', async () => {
        const element = createTypeahead({ label: 'Vehicle asset', minLength: 3 });
        const handler = jest.fn();
        element.addEventListener('search', handler);

        await typeTerm(element, 'ab');

        expect(handler).not.toHaveBeenCalled();
        expect(element.shadowRoot.textContent).toContain('Type at least 3 characters to search.');
    });

    it('fires search with the term when minLength is met', async () => {
        const element = createTypeahead({ label: 'Vehicle asset', minLength: 3 });
        const handler = jest.fn();
        element.addEventListener('search', handler);

        await typeTerm(element, 'abc');

        expect(handler).toHaveBeenCalledTimes(1);
        expect(handler.mock.calls[0][0].detail).toEqual({ term: 'abc' });
    });

    it('renders results as options and highlights with keyboard arrows', async () => {
        const element = createTypeahead({ label: 'Vehicle asset', minLength: 3 });
        await typeTerm(element, 'veh');
        element.results = RESULTS;
        await flushPromises();

        const input = getCombobox(element);
        const options = element.shadowRoot.querySelectorAll('[role="option"]');
        expect(options).toHaveLength(2);
        expect(options[0].textContent).toContain('Alpha Vehicle');
        expect(options[1].textContent).toContain('Beta Vehicle');
        expect(input.getAttribute('aria-expanded')).toBe('true');
        expect(input.getAttribute('aria-activedescendant')).toBe(options[0].id);

        input.dispatchEvent(
            new KeyboardEvent('keydown', { key: 'ArrowDown', bubbles: true, cancelable: true })
        );
        await flushPromises();

        expect(input.getAttribute('aria-activedescendant')).toBe(options[1].id);
    });

    it('fires select with id and label when an option is clicked', async () => {
        const element = createTypeahead({ label: 'Vehicle asset', minLength: 3 });
        const handler = jest.fn();
        element.addEventListener('select', handler);

        await typeTerm(element, 'veh');
        element.results = RESULTS;
        await flushPromises();

        const options = element.shadowRoot.querySelectorAll('[role="option"]');
        options[1].click();
        await flushPromises();

        expect(handler).toHaveBeenCalledTimes(1);
        expect(handler.mock.calls[0][0].detail).toEqual({ id: 'a02', label: 'Beta Vehicle' });
        expect(getCombobox(element).value).toBe('Beta Vehicle');
        expect(element.shadowRoot.querySelector('lightning-button-icon')).not.toBeNull();
    });

    it('selects the highlighted option on Enter', async () => {
        const element = createTypeahead({ label: 'Vehicle asset', minLength: 3 });
        const handler = jest.fn();
        element.addEventListener('select', handler);

        const input = await typeTerm(element, 'veh');
        element.results = RESULTS;
        await flushPromises();

        input.dispatchEvent(
            new KeyboardEvent('keydown', { key: 'Enter', bubbles: true, cancelable: true })
        );
        await flushPromises();

        expect(handler.mock.calls[0][0].detail).toEqual({ id: 'a01', label: 'Alpha Vehicle' });
    });

    it('clears the selection from the clear control', async () => {
        const element = createTypeahead({ label: 'Vehicle asset', minLength: 3 });
        const selectHandler = jest.fn();
        const searchHandler = jest.fn();
        element.addEventListener('select', selectHandler);
        element.addEventListener('search', searchHandler);

        await typeTerm(element, 'veh');
        element.results = RESULTS;
        await flushPromises();
        element.shadowRoot.querySelector('[role="option"]').click();
        await flushPromises();

        selectHandler.mockClear();
        searchHandler.mockClear();

        element.shadowRoot.querySelector('lightning-button-icon').click();
        await flushPromises();

        expect(selectHandler.mock.calls[0][0].detail).toEqual({ id: null, label: null });
        expect(searchHandler.mock.calls[0][0].detail).toEqual({ term: '' });
        expect(getCombobox(element).value).toBe('');
    });

    it('closes the listbox on Escape', async () => {
        const element = createTypeahead({ label: 'Vehicle asset', minLength: 3 });
        const input = await typeTerm(element, 'veh');
        element.results = RESULTS;
        await flushPromises();
        expect(input.getAttribute('aria-expanded')).toBe('true');

        input.dispatchEvent(
            new KeyboardEvent('keydown', { key: 'Escape', bubbles: true, cancelable: true })
        );
        await flushPromises();

        expect(input.getAttribute('aria-expanded')).toBe('false');
    });

    it('disables the combobox when disabled is set', () => {
        const element = createTypeahead({ label: 'Vehicle asset', disabled: true });
        expect(getCombobox(element).disabled).toBe(true);
    });

    it('shows a required message on blur when nothing is selected', async () => {
        const element = createTypeahead({ label: 'Vehicle asset', required: true });
        getCombobox(element).dispatchEvent(new FocusEvent('blur', { bubbles: true }));
        await flushPromises();

        expect(element.shadowRoot.textContent).toContain('Vehicle asset is required.');
        expect(getCombobox(element).getAttribute('aria-invalid')).toBe('true');
    });
});
