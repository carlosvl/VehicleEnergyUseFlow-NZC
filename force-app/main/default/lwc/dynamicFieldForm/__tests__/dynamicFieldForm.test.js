/*
 * Copyright (c) 2026, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

import { createElement } from 'lwc';
import DynamicFieldForm from 'c/dynamicFieldForm';

const ALL_TYPES = [
    { apiName: 'Name', label: 'Name', type: 'STRING', required: true },
    { apiName: 'FuelConsumption', label: 'Fuel Consumption', type: 'DOUBLE' },
    { apiName: 'Quantity', label: 'Quantity', type: 'INTEGER' },
    { apiName: 'StartDate', label: 'Start Date', type: 'DATE' },
    { apiName: 'IsActive', label: 'Active', type: 'BOOLEAN' },
    {
        apiName: 'FuelType',
        label: 'Fuel Type',
        type: 'PICKLIST',
        picklistOptions: [
            { label: 'Diesel', value: 'Diesel' },
            { label: 'Gasoline', value: 'Gasoline' }
        ]
    },
    {
        apiName: 'OtherEmssnFctrId',
        label: 'Other Emissions Factor',
        type: 'REFERENCE',
        required: true,
        referenceTo: 'OtherEmssnFctr'
    },
    { apiName: 'Notes', label: 'Notes', type: 'TEXTAREA' }
];

async function flushPromises() {
    await Promise.resolve();
    await Promise.resolve();
}

function createForm(props = {}) {
    const element = createElement('c-dynamic-field-form', { is: DynamicFieldForm });
    Object.keys(props).forEach((key) => {
        element[key] = props[key];
    });
    document.body.appendChild(element);
    return element;
}

function submitForm(element) {
    const form = element.shadowRoot.querySelector('form');
    form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
}

describe('c-dynamic-field-form', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('maps field types to lightning inputs, combobox, textarea, and typeahead', () => {
        const element = createForm({ fields: ALL_TYPES });

        expect(element.shadowRoot.querySelectorAll('lightning-input').length).toBe(5);
        expect(element.shadowRoot.querySelectorAll('lightning-combobox').length).toBe(1);
        expect(element.shadowRoot.querySelectorAll('lightning-textarea').length).toBe(1);
        expect(element.shadowRoot.querySelectorAll('c-record-typeahead').length).toBe(1);
        expect(element.shadowRoot.querySelector('lightning-button')).not.toBeNull();
    });

    it('fires change with a values map when a text field changes', async () => {
        const element = createForm({
            fields: [{ apiName: 'Name', label: 'Name', type: 'STRING' }]
        });
        const handler = jest.fn();
        element.addEventListener('change', handler);

        const input = element.shadowRoot.querySelector('lightning-input');
        input.dispatchEvent(new CustomEvent('change', { detail: { value: 'Trip 1' } }));
        await flushPromises();

        expect(handler).toHaveBeenCalledTimes(1);
        expect(handler.mock.calls[0][0].detail.values).toEqual({ Name: 'Trip 1' });
    });

    it('coerces numeric and boolean changes in the values map', async () => {
        const element = createForm({
            fields: [
                { apiName: 'FuelConsumption', label: 'Fuel Consumption', type: 'DOUBLE' },
                { apiName: 'IsActive', label: 'Active', type: 'BOOLEAN' }
            ]
        });
        const handler = jest.fn();
        element.addEventListener('change', handler);

        const inputs = element.shadowRoot.querySelectorAll('lightning-input');
        const numberInput = Array.from(inputs).find((node) => node.type === 'number');
        const checkbox = Array.from(inputs).find((node) => node.type === 'checkbox');

        numberInput.dispatchEvent(new CustomEvent('change', { detail: { value: '12.5' } }));
        checkbox.dispatchEvent(new CustomEvent('change', { detail: { checked: true } }));
        await flushPromises();

        const lastValues = handler.mock.calls[handler.mock.calls.length - 1][0].detail.values;
        expect(lastValues.FuelConsumption).toBe(12.5);
        expect(lastValues.IsActive).toBe(true);
    });

    it('does not fire submit when required fields are empty', async () => {
        const element = createForm({
            fields: [{ apiName: 'Name', label: 'Name', type: 'STRING', required: true }]
        });
        const handler = jest.fn();
        element.addEventListener('submit', handler);

        submitForm(element);
        await flushPromises();

        expect(handler).not.toHaveBeenCalled();
    });

    it('fires submit with the values map when required fields are filled', async () => {
        const element = createForm({
            fields: [{ apiName: 'Name', label: 'Name', type: 'STRING', required: true }]
        });
        const handler = jest.fn();
        element.addEventListener('submit', handler);

        const input = element.shadowRoot.querySelector('lightning-input');
        input.dispatchEvent(new CustomEvent('change', { detail: { value: 'Trip 1' } }));
        submitForm(element);
        await flushPromises();

        expect(handler).toHaveBeenCalledTimes(1);
        expect(handler.mock.calls[0][0].detail.values).toEqual({ Name: 'Trip 1' });
    });

    it('re-emits nested typeahead search and select with the field apiName', async () => {
        const element = createForm({
            fields: [
                {
                    apiName: 'OtherEmssnFctrId',
                    label: 'Other Emissions Factor',
                    type: 'REFERENCE',
                    referenceTo: 'OtherEmssnFctr'
                }
            ]
        });
        const searchHandler = jest.fn();
        const selectHandler = jest.fn();
        const changeHandler = jest.fn();
        element.addEventListener('search', searchHandler);
        element.addEventListener('select', selectHandler);
        element.addEventListener('change', changeHandler);

        const typeahead = element.shadowRoot.querySelector('c-record-typeahead');
        typeahead.dispatchEvent(new CustomEvent('search', { detail: { term: 'fac' } }));
        typeahead.dispatchEvent(
            new CustomEvent('select', { detail: { id: 'a0x', label: 'Factor A' } })
        );
        await flushPromises();

        expect(searchHandler.mock.calls[0][0].detail).toEqual({
            apiName: 'OtherEmssnFctrId',
            term: 'fac'
        });
        expect(selectHandler.mock.calls[0][0].detail).toEqual({
            apiName: 'OtherEmssnFctrId',
            id: 'a0x',
            label: 'Factor A'
        });
        expect(changeHandler.mock.calls[0][0].detail.values.OtherEmssnFctrId).toBe('a0x');
    });

    it('passes lookupResults into the nested typeahead listbox', async () => {
        const element = createForm({
            fields: [
                {
                    apiName: 'OtherEmssnFctrId',
                    label: 'Other Emissions Factor',
                    type: 'REFERENCE'
                }
            ],
            lookupResults: {
                OtherEmssnFctrId: [{ id: 'a1', label: 'Factor One' }]
            }
        });
        await flushPromises();

        const typeahead = element.shadowRoot.querySelector('c-record-typeahead');
        const options = typeahead.shadowRoot.querySelectorAll('[role="option"]');
        expect(options[0].textContent).toContain('Factor One');
    });

    it('does not fire submit when a required reference field is empty', async () => {
        const element = createForm({
            fields: [
                {
                    apiName: 'OtherEmssnFctrId',
                    label: 'Other Emissions Factor',
                    type: 'REFERENCE',
                    required: true
                }
            ]
        });
        const handler = jest.fn();
        element.addEventListener('submit', handler);

        submitForm(element);
        await flushPromises();

        expect(handler).not.toHaveBeenCalled();
        const typeahead = element.shadowRoot.querySelector('c-record-typeahead');
        expect(typeahead.shadowRoot.textContent).toContain(
            'Other Emissions Factor is required.'
        );
    });
});
