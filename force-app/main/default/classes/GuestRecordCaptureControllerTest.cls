/*
 * Copyright (c) 2026, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo
 * root or https://opensource.org/licenses/Apache-2.0
 */

/**
 * @description Controller façade tests. Unknown config names fail; short terms return empty
 *              when the Vehicle_Energy_Use CMDT row is present in the org.
 */
@IsTest
private class GuestRecordCaptureControllerTest {
    @IsTest
    static void getConfig_unknownName_throwsAura() {
        try {
            GuestRecordCaptureController.getConfig('Not_A_Real_Config');
            Assert.fail('Expected AuraHandledException.');
        } catch (AuraHandledException e) {
            Assert.isTrue(
                e.getMessage().contains('Unknown capture config') || e.getMessage().contains('Script-thrown'),
                e.getMessage()
            );
        }
    }

    @IsTest
    static void searchRecords_unknownName_throwsAura() {
        try {
            GuestRecordCaptureController.searchRecords('Not_A_Real_Config', 'abc', 'parent');
            Assert.fail('Expected AuraHandledException.');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage());
        }
    }

    @IsTest
    static void getFormSchema_unknownName_throwsAura() {
        try {
            GuestRecordCaptureController.getFormSchema('Not_A_Real_Config');
            Assert.fail('Expected AuraHandledException.');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage());
        }
    }

    @IsTest
    static void createRecord_unknownName_throwsAura() {
        try {
            GuestRecordCaptureController.createRecord(
                'Not_A_Real_Config',
                null,
                new Map<String, Object>()
            );
            Assert.fail('Expected AuraHandledException.');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage());
        }
    }

    @IsTest
    static void getConfig_andShortSearch_whenCmdtPresent() {
        Guest_Capture_Config__mdt config = new GuestCaptureConfigSelector()
            .selectByDeveloperName(GuestRecordCaptureTestFactory.CONFIG_NAME);
        if (config == null) {
            // CMDT record is not queryable in this org yet (deploy metadata before asserting happy path).
            return;
        }

        GuestRecordCaptureDto.CaptureConfig dto = GuestRecordCaptureController.getConfig(
            GuestRecordCaptureTestFactory.CONFIG_NAME
        );
        Assert.areEqual(GuestRecordCaptureTestFactory.CONFIG_NAME, dto.developerName);
        Assert.areEqual(3, dto.minSearchLength);
        Assert.areEqual('Vehicle energy use', dto.formTitle);
        Assert.areEqual('Vehicle asset', dto.parentSearchLabel);

        List<GuestRecordCaptureDto.SearchResult> rows = GuestRecordCaptureController.searchRecords(
            GuestRecordCaptureTestFactory.CONFIG_NAME,
            'ab',
            'parent'
        );
        Assert.areEqual(0, rows.size());
    }

    @IsTest
    static void getConfig_stationary_whenCmdtPresent() {
        Guest_Capture_Config__mdt config = new GuestCaptureConfigSelector()
            .selectByDeveloperName(GuestRecordCaptureTestFactory.STATIONARY_CONFIG_NAME);
        if (config == null) {
            return;
        }

        GuestRecordCaptureDto.CaptureConfig dto = GuestRecordCaptureController.getConfig(
            GuestRecordCaptureTestFactory.STATIONARY_CONFIG_NAME
        );
        Assert.areEqual(GuestRecordCaptureTestFactory.STATIONARY_CONFIG_NAME, dto.developerName);
        Assert.areEqual('Stationary energy use', dto.formTitle);
        Assert.areEqual('Stationary asset', dto.parentSearchLabel);
        Assert.areEqual('kWh', dto.defaultFieldValues.get('FuelConsumptionUnit'));
    }
}
