/*
 * Copyright (c) 2026, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo
 * root or https://opensource.org/licenses/Apache-2.0
 */

/**
 * @description Generic USER_MODE query against an already-allowlisted SObject type.
 *              Object and field API names are taken from describe tokens, never from raw client input.
 */
public inherited sharing virtual class GuestSObjectSelector {
    /**
     * @description Typeahead query using LIKE on a single field. Bind variables for the term and LIMIT.
     * @param sobjectType Allowlisted SObject token from capture config or Field Set referenceTo.
     * @param searchFieldApiName Field to match and return as the result label.
     * @param term Raw search text (LIKE wildcards are stripped).
     * @param resultLimit Positive SOQL LIMIT (caller caps this).
     * @return Matching rows with Id and the search field populated.
     */
    public virtual List<SObject> selectBySearchTerm(
        Schema.SObjectType sobjectType,
        String searchFieldApiName,
        String term,
        Integer resultLimit
    ) {
        if (sobjectType == null) {
            throw new GuestRecordCaptureException('A search object is required.');
        }
        Schema.DescribeSObjectResult objectDescribe = sobjectType.getDescribe();
        Schema.SObjectField searchField = objectDescribe.fields.getMap().get(searchFieldApiName);
        if (searchField == null) {
            throw new GuestRecordCaptureException('Unknown search field in capture config.');
        }
        String objectName = objectDescribe.getName();
        String fieldName = searchField.getDescribe().getName();
        String likeTerm = '%' + sanitizeLikeTerm(term) + '%';
        Integer queryLimit = resultLimit;
        String soql =
            'SELECT Id, ' +
            fieldName +
            ' FROM ' +
            objectName +
            ' WHERE ' +
            fieldName +
            ' LIKE :likeTerm ORDER BY ' +
            fieldName +
            ' LIMIT :queryLimit';
        return Database.query(soql, AccessLevel.USER_MODE);
    }

    /**
     * @description Loads one record by Id with an allowlisted field list. Always includes Id.
     * @param sobjectType Allowlisted SObject token from capture config.
     * @param recordId Record Id to load.
     * @param fieldApiNames Additional fields to select (validated against describe).
     * @return Matching row, or null when none is visible.
     */
    public virtual SObject selectById(
        Schema.SObjectType sobjectType,
        Id recordId,
        List<String> fieldApiNames
    ) {
        if (sobjectType == null) {
            throw new GuestRecordCaptureException('A search object is required.');
        }
        if (recordId == null) {
            throw new GuestRecordCaptureException('Parent Id is required.');
        }
        Schema.DescribeSObjectResult objectDescribe = sobjectType.getDescribe();
        Set<String> qualified = new Set<String>{ 'Id' };
        if (fieldApiNames != null) {
            for (String fieldApiName : fieldApiNames) {
                if (String.isBlank(fieldApiName)) {
                    continue;
                }
                Schema.SObjectField token = objectDescribe.fields.getMap().get(fieldApiName);
                if (token == null) {
                    throw new GuestRecordCaptureException('Unknown field in capture config.');
                }
                qualified.add(token.getDescribe().getName());
            }
        }
        String objectName = objectDescribe.getName();
        String soql =
            'SELECT ' +
            String.join(new List<String>(qualified), ', ') +
            ' FROM ' +
            objectName +
            ' WHERE Id = :recordId LIMIT 1';
        List<SObject> rows = Database.query(soql, AccessLevel.USER_MODE);
        return rows.isEmpty() ? null : rows[0];
    }

    private static String sanitizeLikeTerm(String term) {
        if (String.isBlank(term)) {
            return '';
        }
        return term.replace('%', '').replace('_', '');
    }
}
