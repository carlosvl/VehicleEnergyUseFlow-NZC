/*
 * Copyright (c) 2026, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

import { LightningElement, api, track } from 'lwc';

const BOOLEAN_TYPE = 'BOOLEAN';
const PICKLIST_TYPE = 'PICKLIST';
const TEXTAREA_TYPE = 'TEXTAREA';
const REFERENCE_TYPE = 'REFERENCE';
const INTEGER_TYPES = ['INTEGER', 'INT'];
const DOUBLE_TYPES = ['DOUBLE', 'NUMBER', 'CURRENCY', 'PERCENT'];

/**
 * Object-agnostic form driven by FieldDescriptor-like rows. Does not import Apex
 * and does not know Salesforce object API names.
 */
export default class DynamicFieldForm extends LightningElement {
    /**
     * FieldDescriptor rows: {apiName, label, type, required, picklistOptions, referenceTo}.
     * Optional extras: placeholder, results (lookup rows when lookupResults is not used).
     * @type {Array<object>}
     */
    @api fields;

    /**
     * Lookup typeahead results keyed by field apiName: { [apiName]: [{id, label}] }.
     * Replace the object when results change (LWC does not deep-observe mutations).
     * @type {Object}
     */
    @api lookupResults;

    /**
     * When true, all inputs and the submit button are disabled.
     * @type {boolean}
     */
    @api disabled = false;

    /**
     * Submit button label.
     * @type {string}
     */
    @api submitLabel = 'Submit';

    /**
     * minLength passed to nested record typeaheads for REFERENCE fields.
     * @type {number}
     */
    @api typeaheadMinLength = 3;

    @track _values = {};
    @track _lookupLabels = {};
    @track _submitted = false;

    /**
     * Current / seed values keyed by field apiName. Reference fields store the selected record id.
     * @type {Object}
     */
    @api
    get values() {
        return this.exportValues();
    }
    set values(val) {
        this._values = val && typeof val === 'object' ? { ...val } : {};
    }

    get fieldModels() {
        return this.normalizedFields.map((field) => {
            const type = this.normalizeType(field.type);
            const apiName = field.apiName;
            const label = field.label || apiName;
            const required = field.required === true;
            const currentValue = this._values[apiName];
            const isBoolean = type === BOOLEAN_TYPE;
            const isPicklist = type === PICKLIST_TYPE;
            const isTextarea = type === TEXTAREA_TYPE;
            const isReference = type === REFERENCE_TYPE;
            const isSimpleInput = !isBoolean && !isPicklist && !isTextarea && !isReference;
            return {
                apiName,
                label,
                type,
                required,
                placeholder: field.placeholder || '',
                isBoolean,
                isPicklist,
                isTextarea,
                isReference,
                isSimpleInput,
                booleanValue: currentValue === true,
                displayValue: isBoolean ? undefined : this.toDisplayValue(currentValue),
                comboboxOptions: this.normalizePicklistOptions(field.picklistOptions),
                inputType: this.toInputType(type),
                numberStep: this.toNumberStep(type),
                results: this.getResultsForField(apiName, field),
                selectedLabel:
                    this._lookupLabels[apiName] || field.selectedLabel || '',
                showError:
                    this._submitted &&
                    required &&
                    !isBoolean &&
                    this.isBlank(currentValue),
                errorMessage: `${label} is required.`
            };
        });
    }

    handleFieldChange(event) {
        const target = event.currentTarget || event.target;
        const apiName = (target.dataset && target.dataset.apiName) || target.name;
        if (!apiName) {
            return;
        }
        const fieldType = ((target.dataset && target.dataset.fieldType) || '').toUpperCase();
        this._values = {
            ...this._values,
            [apiName]: this.coerceValue(fieldType, event)
        };
        this.dispatchChange();
    }

    handleLookupSearch(event) {
        const apiName = event.currentTarget.dataset.apiName;
        const term = event.detail && event.detail.term;
        this.dispatchEvent(
            new CustomEvent('search', {
                detail: { apiName, term }
            })
        );
    }

    handleLookupSelect(event) {
        const apiName = event.currentTarget.dataset.apiName;
        const id = event.detail && event.detail.id != null ? event.detail.id : null;
        const label = event.detail && event.detail.label != null ? event.detail.label : null;
        this._values = { ...this._values, [apiName]: id };
        this._lookupLabels = { ...this._lookupLabels, [apiName]: label || '' };
        this.dispatchEvent(
            new CustomEvent('select', {
                detail: { apiName, id, label }
            })
        );
        this.dispatchChange();
    }

    handleSubmit(event) {
        event.preventDefault();
        event.stopPropagation();
        if (this.disabled) {
            return;
        }
        this._submitted = true;

        let allValid = true;
        const inputs = this.template.querySelectorAll(
            'lightning-input, lightning-combobox, lightning-textarea'
        );
        inputs.forEach((input) => {
            if (typeof input.reportValidity === 'function' && input.reportValidity() === false) {
                allValid = false;
            }
        });

        const typeaheads = this.template.querySelectorAll('c-record-typeahead');
        typeaheads.forEach((typeahead) => {
            if (
                typeof typeahead.reportValidity === 'function' &&
                typeahead.reportValidity() === false
            ) {
                allValid = false;
            }
        });

        this.normalizedFields.forEach((field) => {
            const type = this.normalizeType(field.type);
            if (field.required === true && type !== BOOLEAN_TYPE && this.isBlank(this._values[field.apiName])) {
                allValid = false;
            }
        });

        if (!allValid) {
            return;
        }

        this.dispatchEvent(
            new CustomEvent('capturesave', {
                detail: { values: this.exportValues() }
            })
        );
    }

    dispatchChange() {
        this.dispatchEvent(
            new CustomEvent('change', {
                detail: { values: this.exportValues() }
            })
        );
    }

    get normalizedFields() {
        if (!Array.isArray(this.fields)) {
            return [];
        }
        return this.fields.filter((field) => field && field.apiName);
    }

    exportValues() {
        const values = {};
        this.normalizedFields.forEach((field) => {
            const type = this.normalizeType(field.type);
            if (Object.prototype.hasOwnProperty.call(this._values, field.apiName)) {
                values[field.apiName] = this._values[field.apiName];
            } else if (type === BOOLEAN_TYPE) {
                values[field.apiName] = false;
            } else {
                values[field.apiName] = null;
            }
        });
        return values;
    }

    getResultsForField(apiName, field) {
        if (this.lookupResults && Array.isArray(this.lookupResults[apiName])) {
            return this.lookupResults[apiName];
        }
        if (field && Array.isArray(field.results)) {
            return field.results;
        }
        return [];
    }

    normalizeType(type) {
        return type ? String(type).toUpperCase() : 'STRING';
    }

    toInputType(type) {
        if (INTEGER_TYPES.includes(type) || DOUBLE_TYPES.includes(type)) {
            return 'number';
        }
        if (type === 'DATE') {
            return 'date';
        }
        if (type === 'DATETIME') {
            return 'datetime';
        }
        if (type === 'EMAIL') {
            return 'email';
        }
        if (type === 'PHONE') {
            return 'tel';
        }
        if (type === 'URL') {
            return 'url';
        }
        if (type === 'TIME') {
            return 'time';
        }
        return 'text';
    }

    toNumberStep(type) {
        if (INTEGER_TYPES.includes(type)) {
            return '1';
        }
        if (DOUBLE_TYPES.includes(type)) {
            return 'any';
        }
        return undefined;
    }

    toDisplayValue(value) {
        if (value === undefined || value === null) {
            return '';
        }
        return value;
    }

    normalizePicklistOptions(options) {
        if (!Array.isArray(options)) {
            return [];
        }
        return options.map((opt) => {
            if (typeof opt === 'string') {
                return { label: opt, value: opt };
            }
            const value = opt.value != null ? opt.value : opt.apiName;
            const label = opt.label != null ? opt.label : value;
            return { label, value };
        });
    }

    coerceValue(fieldType, event) {
        const target = event.currentTarget || event.target;
        if (fieldType === BOOLEAN_TYPE || target.type === 'checkbox') {
            return event.detail && event.detail.checked === true;
        }
        const raw = event.detail ? event.detail.value : undefined;
        if (INTEGER_TYPES.includes(fieldType) || DOUBLE_TYPES.includes(fieldType)) {
            if (raw === '' || raw === null || raw === undefined) {
                return null;
            }
            const parsed = Number(raw);
            if (Number.isNaN(parsed)) {
                return null;
            }
            return INTEGER_TYPES.includes(fieldType) ? Math.trunc(parsed) : parsed;
        }
        return raw;
    }

    isBlank(value) {
        if (value === null || value === undefined) {
            return true;
        }
        if (typeof value === 'string' && value.trim() === '') {
            return true;
        }
        return false;
    }
}
