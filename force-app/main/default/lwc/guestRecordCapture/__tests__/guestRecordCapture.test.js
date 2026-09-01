/*
 * Copyright (c) 2026, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

import { createElement } from 'lwc';
import GuestRecordCapture from 'c/guestRecordCapture';
import {
    getConfig,
    getFormSchema,
    searchRecords,
    createRecord
} from 'c/guestRecordCaptureService';

jest.mock('c/guestRecordCaptureService', () => {
    return {
        getConfig: jest.fn(),
        getFormSchema: jest.fn(),
        searchRecords: jest.fn(),
        createRecord: jest.fn()
    };
});

const PARENT_ID = 'a0A000000000001AAA';
const FACTOR_ID = 'a0B000000000001AAA';
const CREATED_ID = 'a0C000000000001AAA';

const MOCK_CONFIG = {
    developerName: 'Vehicle_Energy_Use',
    minSearchLength: 3,
    resultLimit: 25,
    defaultFieldValues: { FuelEfficiencyUnit: 'MILES_PER_GALLON' },
    formTitle: 'Vehicle energy use',
    parentSearchLabel: 'Vehicle asset',
    submitLabel: 'Create energy use record'
};

const MOCK_SCHEMA = [
    { apiName: 'Name', label: 'Name', type: 'STRING', required: true },
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
        referenceTo: ['OtherEmssnFctrSet']
    }
];

const PARENT_RESULTS = [
    { id: PARENT_ID, label: 'Alpha Vehicle' },
    { id: 'a0A000000000002AAA', label: 'Beta Vehicle' }
];

async function flushPromises() {
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();
}

function createComposer(props = {}) {
    const element = createElement('c-guest-record-capture', { is: GuestRecordCapture });
    Object.keys(props).forEach((key) => {
        element[key] = props[key];
    });
    document.body.appendChild(element);
    return element;
}

async function createLoadedComposer(props = {}) {
    const element = createComposer(props);
    await flushPromises();
    return element;
}

function getParentTypeahead(element) {
    return element.shadowRoot.querySelector('c-record-typeahead');
}

function getForm(element) {
    return element.shadowRoot.querySelector('c-dynamic-field-form');
}

function getStatus(element) {
    return element.shadowRoot.querySelector('c-inline-status');
}

async function typeIntoTypeahead(typeahead, term) {
    const input = typeahead.shadowRoot.querySelector('[role="combobox"]');
    input.value = term;
    input.dispatchEvent(new Event('input', { bubbles: true }));
    await flushPromises();
    return input;
}

async function selectParent(element, id = PARENT_ID, label = 'Alpha Vehicle') {
    const typeahead = getParentTypeahead(element);
    typeahead.dispatchEvent(new CustomEvent('select', { detail: { id, label } }));
    await flushPromises();
}

function submitForm(form) {
    const nativeForm = form.shadowRoot.querySelector('form');
    nativeForm.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
}

describe('c-guest-record-capture', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
        jest.useRealTimers();
    });

    beforeEach(() => {
        getConfig.mockResolvedValue(MOCK_CONFIG);
        getFormSchema.mockResolvedValue(MOCK_SCHEMA);
        searchRecords.mockResolvedValue([]);
        createRecord.mockResolvedValue(CREATED_ID);
    });

    it('renders the form from the mock schema after load', async () => {
        const element = await createLoadedComposer();

        expect(element.shadowRoot.querySelector('lightning-spinner')).toBeNull();
        const form = getForm(element);
        expect(form).not.toBeNull();
        expect(form.shadowRoot.querySelectorAll('lightning-input').length).toBe(1);
        expect(form.shadowRoot.querySelectorAll('lightning-combobox').length).toBe(1);
        expect(form.shadowRoot.querySelectorAll('c-record-typeahead').length).toBe(1);
        expect(form.shadowRoot.querySelector('lightning-input').label).toBe('Name');
        expect(form.shadowRoot.querySelector('lightning-combobox').label).toBe('Fuel Type');
        expect(
            form.shadowRoot.querySelector('c-record-typeahead').shadowRoot.textContent
        ).toContain('Other Emissions Factor');
        expect(element.shadowRoot.querySelector('.slds-card__header-title').textContent).toContain(
            'Vehicle energy use'
        );
        expect(getParentTypeahead(element).shadowRoot.textContent).toContain('Vehicle asset');
        expect(getForm(element).submitLabel).toBe('Create energy use record');
        expect(form.shadowRoot.querySelector('lightning-button').disabled).toBe(true);
    });

    it('renders the heading from mocked config', async () => {
        const element = await createLoadedComposer();

        expect(element.shadowRoot.querySelector('h2').textContent).toContain('Vehicle energy use');
        expect(getParentTypeahead(element).label).toBe('Vehicle asset');
    });

    it('falls back to default labels when config titles are blank', async () => {
        getConfig.mockResolvedValue({
            ...MOCK_CONFIG,
            formTitle: '',
            parentSearchLabel: '  ',
            submitLabel: null
        });
        const element = await createLoadedComposer();

        expect(element.shadowRoot.querySelector('h2').textContent).toContain('Record capture');
        expect(getParentTypeahead(element).label).toBe('Parent record');
        expect(getForm(element).submitLabel).toBe('Create record');
    });

    it('debounces parent search and renders results', async () => {
        searchRecords.mockResolvedValue(PARENT_RESULTS);
        const element = await createLoadedComposer();
        const typeahead = getParentTypeahead(element);

        jest.useFakeTimers();
        await typeIntoTypeahead(typeahead, 'veh');
        expect(searchRecords).not.toHaveBeenCalled();

        await typeIntoTypeahead(typeahead, 'vehi');
        jest.advanceTimersByTime(299);
        expect(searchRecords).not.toHaveBeenCalled();
        jest.advanceTimersByTime(1);
        jest.useRealTimers();
        await flushPromises();

        expect(searchRecords).toHaveBeenCalledTimes(1);
        expect(searchRecords).toHaveBeenCalledWith('Vehicle_Energy_Use', 'vehi', 'parent');
        const options = typeahead.shadowRoot.querySelectorAll('[role="option"]');
        expect(options).toHaveLength(2);
        expect(options[0].textContent).toContain('Alpha Vehicle');
        expect(options[1].textContent).toContain('Beta Vehicle');
    });

    it('debounces lookup search with the field API name as purpose', async () => {
        const element = await createLoadedComposer();
        await selectParent(element);

        searchRecords.mockResolvedValue([{ id: FACTOR_ID, label: 'Factor One' }]);
        const lookup = getForm(element).shadowRoot.querySelector('c-record-typeahead');

        jest.useFakeTimers();
        await typeIntoTypeahead(lookup, 'fac');
        expect(searchRecords).not.toHaveBeenCalled();
        jest.advanceTimersByTime(300);
        jest.useRealTimers();
        await flushPromises();

        expect(searchRecords).toHaveBeenCalledWith('Vehicle_Energy_Use', 'fac', 'OtherEmssnFctrId');
        const options = lookup.shadowRoot.querySelectorAll('[role="option"]');
        expect(options[0].textContent).toContain('Factor One');
    });

    it('submits createRecord with the parent id and form values', async () => {
        const element = await createLoadedComposer();
        await selectParent(element);

        const form = getForm(element);
        expect(form.shadowRoot.querySelector('lightning-button').disabled).toBe(false);

        const nameInput = form.shadowRoot.querySelector('lightning-input');
        nameInput.dispatchEvent(new CustomEvent('change', { detail: { value: 'Trip 1' } }));
        const lookup = form.shadowRoot.querySelector('c-record-typeahead');
        lookup.dispatchEvent(
            new CustomEvent('select', { detail: { id: FACTOR_ID, label: 'Factor One' } })
        );
        await flushPromises();

        submitForm(form);
        await flushPromises();

        expect(createRecord).toHaveBeenCalledTimes(1);
        expect(createRecord).toHaveBeenCalledWith(
            'Vehicle_Energy_Use',
            PARENT_ID,
            expect.objectContaining({
                Name: 'Trip 1',
                OtherEmssnFctrId: FACTOR_ID
            })
        );
        expect(getStatus(element).shadowRoot.textContent).toContain('Record created successfully.');
    });

    it('shows an inline error when createRecord fails', async () => {
        createRecord.mockRejectedValue({ body: { message: 'Create failed.' } });
        const element = await createLoadedComposer();
        await selectParent(element);

        const form = getForm(element);
        form.shadowRoot
            .querySelector('lightning-input')
            .dispatchEvent(new CustomEvent('change', { detail: { value: 'Trip 1' } }));
        form.shadowRoot.querySelector('c-record-typeahead').dispatchEvent(
            new CustomEvent('select', { detail: { id: FACTOR_ID, label: 'Factor One' } })
        );
        await flushPromises();

        submitForm(form);
        await flushPromises();

        expect(createRecord).toHaveBeenCalledTimes(1);
        const status = getStatus(element);
        expect(status.shadowRoot.querySelector('[role="alert"]')).not.toBeNull();
        expect(status.shadowRoot.textContent).toContain('Create failed.');
        expect(status.shadowRoot.textContent).not.toContain('Record created successfully.');
    });

    it('shows an inline error and hides the form when config load fails', async () => {
        getConfig.mockRejectedValue({ body: { message: 'Unknown capture config.' } });
        const element = await createLoadedComposer();

        expect(getForm(element)).toBeNull();
        expect(getParentTypeahead(element)).toBeNull();
        const status = getStatus(element);
        expect(status.shadowRoot.querySelector('[role="alert"]')).not.toBeNull();
        expect(status.shadowRoot.textContent).toContain('Unknown capture config.');
    });
});
