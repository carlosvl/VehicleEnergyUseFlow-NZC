/*
 * Copyright (c) 2026, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo
 * root or https://opensource.org/licenses/Apache-2.0
 */

/**
 * @description USER_MODE search tests against Account (always present, unlike NZC objects).
 */
@IsTest
private class GuestSObjectSelectorTest {
    @IsTest
    static void selectBySearchTerm_nullType_throws() {
        try {
            new GuestSObjectSelector().selectBySearchTerm(null, 'Name', 'abc', 25);
            Assert.fail('Expected missing object type to fail.');
        } catch (GuestRecordCaptureException e) {
            Assert.isTrue(e.getMessage().contains('search object'), e.getMessage());
        }
    }

    @IsTest
    static void selectBySearchTerm_unknownField_throws() {
        try {
            new GuestSObjectSelector().selectBySearchTerm(Account.SObjectType, 'NoSuchField__c', 'abc', 25);
            Assert.fail('Expected unknown field to fail.');
        } catch (GuestRecordCaptureException e) {
            Assert.isTrue(e.getMessage().contains('Unknown search field'), e.getMessage());
        }
    }

    @IsTest
    static void selectBySearchTerm_findsAccountByName() {
        String uniqueName = 'GuestCapSel ' + String.valueOf(Crypto.getRandomInteger());
        Account matching = new Account(Name = uniqueName);
        insert matching;
        insert new Account(Name = 'Unrelated GuestCapSel');

        Test.startTest();
        List<SObject> rows = new GuestSObjectSelector()
            .selectBySearchTerm(Account.SObjectType, 'Name', uniqueName, 25);
        Test.stopTest();

        Assert.areEqual(1, rows.size());
        Assert.areEqual(matching.Id, rows[0].Id);
        Assert.areEqual(uniqueName, (String) rows[0].get('Name'));
    }
}
