/*
 * Copyright (c) 2026, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

import getConfigApex from '@salesforce/apex/GuestRecordCaptureController.getConfig';
import searchRecordsApex from '@salesforce/apex/GuestRecordCaptureController.searchRecords';
import getFormSchemaApex from '@salesforce/apex/GuestRecordCaptureController.getFormSchema';
import createRecordApex from '@salesforce/apex/GuestRecordCaptureController.createRecord';

/**
 * Loads capture config for a Guest_Capture_Config__mdt developer name.
 * @param {string} configName Config developer name.
 * @returns {Promise<object>} CaptureConfig
 */
export function getConfig(configName) {
    return getConfigApex({ configName });
}

/**
 * Typeahead search. Purpose `parent` (or blank) searches the config parent object;
 * any other purpose is a Field Set lookup field API name.
 * @param {string} configName Config developer name.
 * @param {string} term Search text.
 * @param {string} purpose `parent` or a lookup field API name.
 * @returns {Promise<Array<{id: string, label: string}>>}
 */
export function searchRecords(configName, term, purpose) {
    return searchRecordsApex({ configName, term, purpose });
}

/**
 * Field Set schema for the dynamic create form.
 * @param {string} configName Config developer name.
 * @returns {Promise<Array<object>>}
 */
export function getFormSchema(configName) {
    return getFormSchemaApex({ configName });
}

/**
 * Creates a target record. Extra keys are rejected in Apex.
 * @param {string} configName Config developer name.
 * @param {string} parentId Selected parent record Id.
 * @param {object} values Field Set value map.
 * @returns {Promise<string>} Inserted record Id.
 */
export function createRecord(configName, parentId, values) {
    return createRecordApex({ configName, parentId, values });
}
