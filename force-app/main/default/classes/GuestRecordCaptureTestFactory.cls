/*
 * Copyright (c) 2026, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo
 * root or https://opensource.org/licenses/Apache-2.0
 */

/**
 * @description Test-only factory for in-memory capture config and NZC availability checks.
 *              Custom metadata rows are constructed in memory (DML is not allowed on CMDT).
 */
@IsTest
public class GuestRecordCaptureTestFactory {
    public static final String CONFIG_NAME = 'Vehicle_Energy_Use';
    public static final String STATIONARY_CONFIG_NAME = 'Stationary_Energy_Use';

    /**
     * @description In-memory config that allowlists Account search and Contact create.
     *              Safe in orgs without Net Zero Cloud.
     * @return Guest_Capture_Config__mdt instance (not inserted).
     */
    public static Guest_Capture_Config__mdt accountContactConfig() {
        return new Guest_Capture_Config__mdt(
            DeveloperName = CONFIG_NAME,
            MasterLabel = 'Vehicle Energy Use',
            Search_Object__c = 'Account',
            Search_Field__c = 'Name',
            Target_Object__c = 'Contact',
            Parent_Lookup_Field__c = 'AccountId',
            Field_Set_Name__c = 'Guest_Energy_Use_Capture',
            Min_Search_Length__c = 3,
            Result_Limit__c = 25,
            Default_Field_Values__c = '{"Description":"guest-default"}',
            Form_Title__c = 'Vehicle energy use',
            Parent_Search_Label__c = 'Vehicle asset',
            Submit_Label__c = 'Create energy use record'
        );
    }

    /**
     * @description In-memory config pointing at NZC vehicle objects.
     * @return Guest_Capture_Config__mdt instance (not inserted).
     */
    public static Guest_Capture_Config__mdt vehicleEnergyUseConfig() {
        return new Guest_Capture_Config__mdt(
            DeveloperName = CONFIG_NAME,
            MasterLabel = 'Vehicle Energy Use',
            Search_Object__c = 'VehicleAssetEmssnSrc',
            Search_Field__c = 'Name',
            Target_Object__c = 'VehicleAssetEnrgyUse',
            Parent_Lookup_Field__c = 'VehicleAssetEmssnSrcId',
            Field_Set_Name__c = 'Guest_Energy_Use_Capture',
            Min_Search_Length__c = 3,
            Result_Limit__c = 25,
            Default_Field_Values__c = '{"FuelEfficiencyUnit":"MILES_PER_GALLON"}',
            Parent_Copied_Fields__c = '{"OtherEmssnFctrId":"OtherEmssnFctrId"}',
            Form_Title__c = 'Vehicle energy use',
            Parent_Search_Label__c = 'Vehicle asset',
            Submit_Label__c = 'Create energy use record'
        );
    }

    /**
     * @description In-memory config pointing at NZC stationary objects.
     * @return Guest_Capture_Config__mdt instance (not inserted).
     */
    public static Guest_Capture_Config__mdt stationaryEnergyUseConfig() {
        return new Guest_Capture_Config__mdt(
            DeveloperName = STATIONARY_CONFIG_NAME,
            MasterLabel = 'Stationary Energy Use',
            Search_Object__c = 'StnryAssetEnvrSrc',
            Search_Field__c = 'Name',
            Target_Object__c = 'StnryAssetEnrgyUse',
            Parent_Lookup_Field__c = 'StnryAssetEnvrSrcId',
            Field_Set_Name__c = 'Guest_Energy_Use_Capture',
            Min_Search_Length__c = 3,
            Result_Limit__c = 25,
            Default_Field_Values__c = '{"FuelConsumptionUnit":"kWh"}',
            Parent_Copied_Fields__c = '{"OtherEmssnFctrId":"OtherEmssnFctrId"}',
            Form_Title__c = 'Stationary energy use',
            Parent_Search_Label__c = 'Stationary asset',
            Submit_Label__c = 'Create energy use record'
        );
    }

    public static Boolean nzcObjectsAvailable() {
        try {
            Schema.describeSObjects(
                new List<String>{ 'VehicleAssetEmssnSrc', 'VehicleAssetEnrgyUse', 'OtherEmssnFctrSet' }
            );
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public static Boolean vehicleFieldSetAvailable() {
        if (!nzcObjectsAvailable()) {
            return false;
        }
        Schema.SObjectType energyUseType = Schema.describeSObjects(new List<String>{ 'VehicleAssetEnrgyUse' })[0]
            .getSObjectType();
        return energyUseType.getDescribe().fieldSets.getMap().containsKey('Guest_Energy_Use_Capture');
    }

    public static Boolean nzcStationaryObjectsAvailable() {
        try {
            Schema.describeSObjects(
                new List<String>{ 'StnryAssetEnvrSrc', 'StnryAssetEnrgyUse', 'OtherEmssnFctrSet' }
            );
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public static Boolean stationaryFieldSetAvailable() {
        if (!nzcStationaryObjectsAvailable()) {
            return false;
        }
        Schema.SObjectType energyUseType = Schema.describeSObjects(new List<String>{ 'StnryAssetEnrgyUse' })[0]
            .getSObjectType();
        return energyUseType.getDescribe().fieldSets.getMap().containsKey('Guest_Energy_Use_Capture');
    }

    public static GuestRecordCaptureDto.FieldDescriptor descriptor(
        String apiName,
        String typeName,
        Boolean required,
        List<String> referenceTo
    ) {
        GuestRecordCaptureDto.FieldDescriptor field = new GuestRecordCaptureDto.FieldDescriptor();
        field.apiName = apiName;
        field.label = apiName;
        field.type = typeName;
        field.required = required;
        field.picklistOptions = new List<GuestRecordCaptureDto.PicklistOption>();
        field.referenceTo = referenceTo == null ? new List<String>() : referenceTo;
        return field;
    }
}
