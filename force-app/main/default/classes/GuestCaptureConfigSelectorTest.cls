/*
 * Copyright (c) 2026, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo
 * root or https://opensource.org/licenses/Apache-2.0
 */

/**
 * @description Selector tests for Guest_Capture_Config__mdt.
 */
@IsTest
private class GuestCaptureConfigSelectorTest {
    @IsTest
    static void selectByDeveloperName_blank_returnsNull() {
        GuestCaptureConfigSelector selector = new GuestCaptureConfigSelector();
        Assert.isNull(selector.selectByDeveloperName(null));
        Assert.isNull(selector.selectByDeveloperName(''));
    }

    @IsTest
    static void selectByDeveloperName_unknown_returnsNull() {
        GuestCaptureConfigSelector selector = new GuestCaptureConfigSelector();
        Assert.isNull(selector.selectByDeveloperName('Definitely_Not_A_Capture_Config'));
    }

    @IsTest
    static void selectByDeveloperName_vehicleEnergyUse_whenPresent() {
        Guest_Capture_Config__mdt config = new GuestCaptureConfigSelector()
            .selectByDeveloperName(GuestRecordCaptureTestFactory.CONFIG_NAME);
        if (config == null) {
            return;
        }
        Assert.areEqual('VehicleAssetEmssnSrc', config.Search_Object__c);
        Assert.areEqual('Name', config.Search_Field__c);
        Assert.areEqual('VehicleAssetEnrgyUse', config.Target_Object__c);
        Assert.areEqual('VehicleAssetEmssnSrcId', config.Parent_Lookup_Field__c);
        Assert.areEqual('Guest_Energy_Use_Capture', config.Field_Set_Name__c);
        Assert.isTrue(config.Default_Field_Values__c.contains('MILES_PER_GALLON'));
        Assert.areEqual('Vehicle energy use', config.Form_Title__c);
        Assert.areEqual('Vehicle asset', config.Parent_Search_Label__c);
        Assert.areEqual('Create energy use record', config.Submit_Label__c);
    }

    @IsTest
    static void selectByDeveloperName_stationaryEnergyUse_whenPresent() {
        Guest_Capture_Config__mdt config = new GuestCaptureConfigSelector()
            .selectByDeveloperName(GuestRecordCaptureTestFactory.STATIONARY_CONFIG_NAME);
        if (config == null) {
            return;
        }
        Assert.areEqual('StnryAssetEnvrSrc', config.Search_Object__c);
        Assert.areEqual('Name', config.Search_Field__c);
        Assert.areEqual('StnryAssetEnrgyUse', config.Target_Object__c);
        Assert.areEqual('StnryAssetEnvrSrcId', config.Parent_Lookup_Field__c);
        Assert.areEqual('Guest_Energy_Use_Capture', config.Field_Set_Name__c);
        Assert.isTrue(config.Default_Field_Values__c.contains('kWh'));
        Assert.areEqual('Stationary energy use', config.Form_Title__c);
        Assert.areEqual('Stationary asset', config.Parent_Search_Label__c);
    }
}
