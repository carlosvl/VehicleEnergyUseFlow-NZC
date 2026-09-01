/*
 * Copyright (c) 2026, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo
 * root or https://opensource.org/licenses/Apache-2.0
 */

/**
 * @description Field Set schema tests. Unknown Field Sets fail; picklist/reference mapping is
 *              covered via describe tokens. NZC Field Set is asserted when present in the org.
 */
@IsTest
private class FieldSetSchemaServiceTest {
    @IsTest
    static void describeFieldSet_missingName_throws() {
        try {
            new FieldSetSchemaService().describeFieldSet(Account.SObjectType, null);
            Assert.fail('Expected missing Field Set name to fail.');
        } catch (GuestRecordCaptureException e) {
            Assert.isTrue(e.getMessage().contains('Field Set name is required'), e.getMessage());
        }
    }

    @IsTest
    static void describeFieldSet_unknownSet_throws() {
        try {
            new FieldSetSchemaService().describeFieldSet(Account.SObjectType, 'Guest_Energy_Use_Capture');
            Assert.fail('Expected unknown Field Set to fail.');
        } catch (GuestRecordCaptureException e) {
            Assert.isTrue(e.getMessage().contains('Unknown Field Set'), e.getMessage());
        }
    }

    @IsTest
    static void describeFieldSet_nullType_throws() {
        try {
            new FieldSetSchemaService().describeFieldSet(null, 'Guest_Energy_Use_Capture');
            Assert.fail('Expected missing object type to fail.');
        } catch (GuestRecordCaptureException e) {
            Assert.isTrue(e.getMessage().contains('target object is required'), e.getMessage());
        }
    }

    @IsTest
    static void toDescriptor_picklistAndReferenceAndNullDescribe() {
        GuestRecordCaptureDto.FieldDescriptor noDescribe = FieldSetSchemaService.toDescriptor(
            'Name',
            'Name',
            true,
            null
        );
        Assert.areEqual('STRING', noDescribe.type);
        Assert.isTrue(noDescribe.required);
        Assert.areEqual(0, noDescribe.picklistOptions.size());

        GuestRecordCaptureDto.FieldDescriptor industry = FieldSetSchemaService.toDescriptor(
            'Industry',
            'Industry',
            false,
            Account.Industry.getDescribe()
        );
        Assert.areEqual('PICKLIST', industry.type);
        Assert.isTrue(industry.picklistOptions.size() > 0);

        GuestRecordCaptureDto.FieldDescriptor parent = FieldSetSchemaService.toDescriptor(
            'ParentId',
            'Parent Account',
            false,
            Account.ParentId.getDescribe()
        );
        Assert.areEqual('REFERENCE', parent.type);
        Assert.isTrue(parent.referenceTo.contains('Account'));
    }

    @IsTest
    static void getAllowedFieldNames_fromDescribedMembers() {
        Set<String> names = new DescriptorStub().getAllowedFieldNames(Account.SObjectType, 'Guest_Energy_Use_Capture');
        Assert.isTrue(names.contains('LastName'));
        Assert.areEqual(1, names.size());
    }

    @IsTest
    static void getAllowedFieldNames_vehicleFieldSet_whenPresent() {
        if (!GuestRecordCaptureTestFactory.vehicleFieldSetAvailable()) {
            return;
        }
        Schema.SObjectType energyUseType = Schema.describeSObjects(new List<String>{ 'VehicleAssetEnrgyUse' })[0]
            .getSObjectType();
        FieldSetSchemaService schemaService = new FieldSetSchemaService();
        Set<String> allowed = schemaService.getAllowedFieldNames(energyUseType, 'Guest_Energy_Use_Capture');
        Assert.isTrue(allowed.contains('Name'));
        Assert.isTrue(allowed.contains('OtherEmssnFctrId'));
        Assert.isTrue(allowed.contains('FuelType'));
        Assert.isTrue(allowed.contains('FuelConsumption'));
        Assert.isTrue(allowed.contains('FuelConsumptionUnit'));
        Assert.isTrue(allowed.contains('FuelEfficiencyUnit'));
        Assert.isFalse(allowed.contains('VehicleAssetEmssnSrcId'));

        List<GuestRecordCaptureDto.FieldDescriptor> descriptors = schemaService.describeFieldSet(
            energyUseType,
            'Guest_Energy_Use_Capture'
        );
        Map<String, GuestRecordCaptureDto.FieldDescriptor> apiNameToField = new Map<String, GuestRecordCaptureDto.FieldDescriptor>();
        for (GuestRecordCaptureDto.FieldDescriptor descriptor : descriptors) {
            apiNameToField.put(descriptor.apiName, descriptor);
        }
        Assert.isTrue(apiNameToField.get('Name').required);
        Assert.isTrue(apiNameToField.get('OtherEmssnFctrId').required);
        Assert.isFalse(apiNameToField.get('StartDate').required);
        Assert.isTrue(apiNameToField.get('OtherEmssnFctrId').referenceTo.contains('OtherEmssnFctrSet'));
        Assert.isTrue(apiNameToField.get('FuelType').picklistOptions.size() > 0);
    }

    @IsTest
    static void getAllowedFieldNames_stationaryFieldSet_whenPresent() {
        if (!GuestRecordCaptureTestFactory.stationaryFieldSetAvailable()) {
            return;
        }
        Schema.SObjectType energyUseType = Schema.describeSObjects(new List<String>{ 'StnryAssetEnrgyUse' })[0]
            .getSObjectType();
        FieldSetSchemaService schemaService = new FieldSetSchemaService();
        Set<String> allowed = schemaService.getAllowedFieldNames(energyUseType, 'Guest_Energy_Use_Capture');
        Assert.isTrue(allowed.contains('Name'));
        Assert.isTrue(allowed.contains('OtherEmssnFctrId'));
        Assert.isTrue(allowed.contains('FuelType'));
        Assert.isTrue(allowed.contains('FuelConsumption'));
        Assert.isTrue(allowed.contains('FuelConsumptionUnit'));
        Assert.isTrue(allowed.contains('StartDate'));
        Assert.isTrue(allowed.contains('EndDate'));
        Assert.isFalse(allowed.contains('StnryAssetEnvrSrcId'));
        Assert.isFalse(allowed.contains('FuelEfficiency'));
        Assert.isFalse(allowed.contains('FuelEfficiencyUnit'));

        List<GuestRecordCaptureDto.FieldDescriptor> descriptors = schemaService.describeFieldSet(
            energyUseType,
            'Guest_Energy_Use_Capture'
        );
        Map<String, GuestRecordCaptureDto.FieldDescriptor> apiNameToField = new Map<String, GuestRecordCaptureDto.FieldDescriptor>();
        for (GuestRecordCaptureDto.FieldDescriptor descriptor : descriptors) {
            apiNameToField.put(descriptor.apiName, descriptor);
        }
        Assert.isTrue(apiNameToField.get('Name').required);
        Assert.isTrue(apiNameToField.get('OtherEmssnFctrId').required);
        Assert.isFalse(apiNameToField.get('StartDate').required);
        Assert.isTrue(apiNameToField.get('OtherEmssnFctrId').referenceTo.contains('OtherEmssnFctrSet'));
    }

    private class DescriptorStub extends FieldSetSchemaService {
        public override List<GuestRecordCaptureDto.FieldDescriptor> describeFieldSet(
            Schema.SObjectType sobjectType,
            String fieldSetName
        ) {
            return new List<GuestRecordCaptureDto.FieldDescriptor>{
                GuestRecordCaptureTestFactory.descriptor('LastName', 'STRING', true, null)
            };
        }
    }
}
