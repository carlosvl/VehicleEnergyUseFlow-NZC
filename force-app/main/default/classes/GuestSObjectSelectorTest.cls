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

    @IsTest
    static void selectById_nullType_throws() {
        try {
            new GuestSObjectSelector().selectById(null, UserInfo.getUserId(), new List<String>{ 'Name' });
            Assert.fail('Expected missing object type to fail.');
        } catch (GuestRecordCaptureException e) {
            Assert.isTrue(e.getMessage().contains('search object'), e.getMessage());
        }
    }

    @IsTest
    static void selectById_nullId_throws() {
        try {
            new GuestSObjectSelector().selectById(Account.SObjectType, null, new List<String>{ 'Name' });
            Assert.fail('Expected missing Id to fail.');
        } catch (GuestRecordCaptureException e) {
            Assert.isTrue(e.getMessage().contains('Parent Id is required'), e.getMessage());
        }
    }

    @IsTest
    static void selectById_unknownField_throws() {
        Account parent = new Account(Name = 'GuestCapSel ById');
        insert parent;
        try {
            new GuestSObjectSelector()
                .selectById(Account.SObjectType, parent.Id, new List<String>{ 'NoSuchField__c' });
            Assert.fail('Expected unknown field to fail.');
        } catch (GuestRecordCaptureException e) {
            Assert.isTrue(e.getMessage().contains('Unknown field'), e.getMessage());
        }
    }

    @IsTest
    static void selectById_findsAccountFields() {
        Account matching = new Account(Name = 'GuestCapSel Phone', Phone = '5550199');
        insert matching;

        Test.startTest();
        SObject row = new GuestSObjectSelector()
            .selectById(Account.SObjectType, matching.Id, new List<String>{ 'Phone', 'Name' });
        Test.stopTest();

        Assert.isNotNull(row);
        Assert.areEqual(matching.Id, row.Id);
        Assert.areEqual('5550199', (String) row.get('Phone'));
        Assert.areEqual('GuestCapSel Phone', (String) row.get('Name'));
    }

    @IsTest
    static void selectById_missingRecord_returnsNull() {
        SObject row = new GuestSObjectSelector()
            .selectById(Account.SObjectType, UserInfo.getUserId(), new List<String>{ 'Name' });
        Assert.isNull(row);
    }
}
