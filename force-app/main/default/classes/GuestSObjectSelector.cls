/*
 * Copyright (c) 2026, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo
 * root or https://opensource.org/licenses/Apache-2.0
 */

/**
 * @description Generic USER_MODE search against an already-allowlisted SObject type.
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

    private static String sanitizeLikeTerm(String term) {
        if (String.isBlank(term)) {
            return '';
        }
        return term.replace('%', '').replace('_', '');
    }
}
