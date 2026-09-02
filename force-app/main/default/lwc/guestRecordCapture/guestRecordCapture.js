/*
 * Copyright (c) 2026, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

import { LightningElement, api, track } from 'lwc';
import {
    getConfig,
    getFormSchema,
    searchRecords,
    createRecord
} from 'c/guestRecordCaptureService';

const DEFAULT_CONFIG_NAME = 'Vehicle_Energy_Use';
const PURPOSE_PARENT = 'parent';
const SEARCH_DEBOUNCE_MS = 300;
const DEFAULT_MIN_SEARCH_LENGTH = 3;
const DEFAULT_FORM_TITLE = 'Record capture';
const DEFAULT_PARENT_SEARCH_LABEL = 'Parent record';
const DEFAULT_SUBMIT_LABEL = 'Create record';
const UNEXPECTED_ERROR = 'An unexpected error occurred.';

/**
 * Experience Cloud composer for guest record capture. Loads config and Field Set
 * schema, wires presentational typeahead/form/status, and calls the data module.
 */
export default class GuestRecordCapture extends LightningElement {
    /**
     * Guest_Capture_Config__mdt developer name. The only value the client sends to Apex.
     * @type {string}
     */
    @api configName = DEFAULT_CONFIG_NAME;

    @track isLoading = true;
    @track isSubmitting = false;
    @track isReady = false;
    @track minSearchLength = DEFAULT_MIN_SEARCH_LENGTH;
    @track fields = [];
    @track formValues = {};
    @track lookupResults = {};
    @track parentResults = [];
    @track parentId = null;
    @track parentLabel = '';
    @track statusVariant = 'info';
    @track statusMessage = '';
    @track formTitle = DEFAULT_FORM_TITLE;
    @track parentSearchLabel = DEFAULT_PARENT_SEARCH_LABEL;
    @track submitLabel = DEFAULT_SUBMIT_LABEL;

    _parentSearchTimer;
    _lookupSearchTimers = {};
    _parentSearchSeq = 0;
    _lookupSearchSeq = {};
    _defaultFieldValues = {};

    async connectedCallback() {
        await this.loadConfigAndSchema();
    }

    disconnectedCallback() {
        this.clearAllTimers();
    }

    get isBusy() {
        return this.isLoading || this.isSubmitting;
    }

    get isFormDisabled() {
        return this.isBusy || !this.parentId;
    }

    get resolvedConfigName() {
        const name = this.configName;
        return typeof name === 'string' && name.trim() ? name.trim() : DEFAULT_CONFIG_NAME;
    }

    handleParentSearch(event) {
        const term = event.detail && event.detail.term != null ? String(event.detail.term) : '';
        this.scheduleTimeout('parent', () => {
            this.runParentSearch(term);
        });
    }

    handleParentSelect(event) {
        const id = event.detail && event.detail.id != null ? event.detail.id : null;
        const label = event.detail && event.detail.label != null ? event.detail.label : null;
        this.parentId = id;
        this.parentLabel = label || '';
        this.parentResults = [];
        if (id) {
            this.clearStatus();
        }
    }

    handleLookupSearch(event) {
        const apiName = event.detail && event.detail.apiName;
        const term = event.detail && event.detail.term != null ? String(event.detail.term) : '';
        if (!apiName) {
            return;
        }
        this.scheduleTimeout(apiName, () => {
            this.runLookupSearch(apiName, term);
        });
    }

    async handleFormSubmit(event) {
        if (!(event.detail && event.detail.values && typeof event.detail.values === 'object')) {
            return;
        }
        const values = event.detail.values;
        if (!this.parentId) {
            this.statusVariant = 'error';
            this.statusMessage = 'Select a parent record before submitting.';
            return;
        }
        this.isSubmitting = true;
        this.clearStatus();
        try {
            await createRecord(this.resolvedConfigName, this.parentId, values);
            this.statusVariant = 'success';
            this.statusMessage = 'Record created successfully.';
            this.resetAfterSuccess();
        } catch (error) {
            this.statusVariant = 'error';
            this.statusMessage = extractErrorMessage(error);
        } finally {
            this.isSubmitting = false;
        }
    }

    async loadConfigAndSchema() {
        this.isLoading = true;
        this.isReady = false;
        this.clearStatus();
        const name = this.resolvedConfigName;
        try {
            const [config, schema] = await Promise.all([getConfig(name), getFormSchema(name)]);
            this.minSearchLength = toMinSearchLength(config);
            this.formTitle = toLabel(config && config.formTitle, DEFAULT_FORM_TITLE);
            this.parentSearchLabel = toLabel(config && config.parentSearchLabel, DEFAULT_PARENT_SEARCH_LABEL);
            this.submitLabel = toLabel(config && config.submitLabel, DEFAULT_SUBMIT_LABEL);
            this._defaultFieldValues =
                config && config.defaultFieldValues && typeof config.defaultFieldValues === 'object'
                    ? { ...config.defaultFieldValues }
                    : {};
            this.formValues = { ...this._defaultFieldValues };
            this.fields = Array.isArray(schema) ? schema : [];
            this.lookupResults = {};
            this.isReady = true;
        } catch (error) {
            this.statusVariant = 'error';
            this.statusMessage = extractErrorMessage(error);
            this.isReady = false;
        } finally {
            this.isLoading = false;
        }
    }

    async runParentSearch(term) {
        const seq = (this._parentSearchSeq += 1);
        const trimmed = term.trim();
        if (trimmed.length === 0 || trimmed.length < this.minSearchLength) {
            this.parentResults = [];
            return;
        }
        try {
            const rows = await searchRecords(this.resolvedConfigName, trimmed, PURPOSE_PARENT);
            if (seq !== this._parentSearchSeq) {
                return;
            }
            this.parentResults = Array.isArray(rows) ? [...rows] : [];
        } catch (error) {
            if (seq !== this._parentSearchSeq) {
                return;
            }
            this.parentResults = [];
            this.statusVariant = 'error';
            this.statusMessage = extractErrorMessage(error);
        }
    }

    async runLookupSearch(apiName, term) {
        const seq = (this._lookupSearchSeq[apiName] = (this._lookupSearchSeq[apiName] || 0) + 1);
        const trimmed = term.trim();
        if (trimmed.length === 0 || trimmed.length < this.minSearchLength) {
            this.replaceLookupResults(apiName, []);
            return;
        }
        try {
            const rows = await searchRecords(this.resolvedConfigName, trimmed, apiName);
            if (seq !== this._lookupSearchSeq[apiName]) {
                return;
            }
            this.replaceLookupResults(apiName, Array.isArray(rows) ? [...rows] : []);
        } catch (error) {
            if (seq !== this._lookupSearchSeq[apiName]) {
                return;
            }
            this.replaceLookupResults(apiName, []);
            this.statusVariant = 'error';
            this.statusMessage = extractErrorMessage(error);
        }
    }

    replaceLookupResults(apiName, rows) {
        this.lookupResults = { ...this.lookupResults, [apiName]: rows };
    }

    resetAfterSuccess() {
        this.parentId = null;
        this.parentLabel = '';
        this.parentResults = [];
        this.lookupResults = {};
        this.formValues = { ...this._defaultFieldValues };
    }

    scheduleTimeout(key, callback) {
        if (key === 'parent') {
            clearTimeout(this._parentSearchTimer);
            this._parentSearchTimer = setTimeout(callback, SEARCH_DEBOUNCE_MS);
            return;
        }
        clearTimeout(this._lookupSearchTimers[key]);
        this._lookupSearchTimers[key] = setTimeout(callback, SEARCH_DEBOUNCE_MS);
    }

    clearAllTimers() {
        clearTimeout(this._parentSearchTimer);
        Object.keys(this._lookupSearchTimers).forEach((key) => {
            clearTimeout(this._lookupSearchTimers[key]);
        });
        this._lookupSearchTimers = {};
    }

    clearStatus() {
        this.statusMessage = '';
        this.statusVariant = 'info';
    }
}

function toMinSearchLength(config) {
    const parsed = Number(config && config.minSearchLength);
    return Number.isFinite(parsed) && parsed > 0 ? parsed : DEFAULT_MIN_SEARCH_LENGTH;
}

function toLabel(value, fallback) {
    return typeof value === 'string' && value.trim() ? value.trim() : fallback;
}

function extractErrorMessage(error) {
    if (!error) {
        return UNEXPECTED_ERROR;
    }
    if (typeof error === 'string' && error.trim()) {
        return error;
    }
    const body = error.body;
    if (typeof body === 'string' && body.trim()) {
        return body;
    }
    if (body && typeof body.message === 'string' && body.message.trim()) {
        return body.message;
    }
    if (Array.isArray(body) && body.length) {
        const messages = body.map((item) => (item && item.message) || '').filter((msg) => msg);
        if (messages.length) {
            return messages.join(' ');
        }
    }
    if (typeof error.message === 'string' && error.message.trim()) {
        return error.message;
    }
    return UNEXPECTED_ERROR;
}
