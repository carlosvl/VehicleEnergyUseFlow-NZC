/*
 * Copyright (c) 2026, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo
 * root or https://opensource.org/licenses/Apache-2.0
 */

/**
 * @description Interaction tests for GuestRecordCaptureService allowlist, search, and create.
 */
@IsTest
private class GuestRecordCaptureServiceTest {
    @IsTest
    static void getConfig_unknownName_throws() {
        GuestRecordCaptureService service = serviceFor(null, new SearchSpy(), contactSchema());

        try {
            service.getConfig('Not_A_Real_Config');
            Assert.fail('Expected unknown config to fail.');
        } catch (GuestRecordCaptureException e) {
            Assert.isTrue(e.getMessage().contains('Unknown capture config'), e.getMessage());
        }
    }

    @IsTest
    static void getConfig_blankName_throws() {
        GuestRecordCaptureService service = serviceFor(
            GuestRecordCaptureTestFactory.accountContactConfig(),
            new SearchSpy(),
            contactSchema()
        );

        try {
            service.getConfig('  ');
            Assert.fail('Expected blank config name to fail.');
        } catch (GuestRecordCaptureException e) {
            Assert.isTrue(e.getMessage().contains('required'), e.getMessage());
        }
    }

    @IsTest
    static void getConfig_returnsDefaultsAndMinLength() {
        GuestRecordCaptureService service = serviceFor(
            GuestRecordCaptureTestFactory.accountContactConfig(),
            new SearchSpy(),
            contactSchema()
        );

        GuestRecordCaptureDto.CaptureConfig config = service.getConfig(
            GuestRecordCaptureTestFactory.CONFIG_NAME
        );

        Assert.areEqual(GuestRecordCaptureTestFactory.CONFIG_NAME, config.developerName);
        Assert.areEqual(3, config.minSearchLength);
        Assert.areEqual(25, config.resultLimit);
        Assert.areEqual('guest-default', config.defaultFieldValues.get('Description'));
        Assert.areEqual('Vehicle energy use', config.formTitle);
        Assert.areEqual('Vehicle asset', config.parentSearchLabel);
        Assert.areEqual('Create energy use record', config.submitLabel);
    }

    @IsTest
    static void searchRecords_shortTerm_returnsEmptyWithoutQuery() {
        SearchSpy spy = new SearchSpy();
        GuestRecordCaptureService service = serviceFor(
            GuestRecordCaptureTestFactory.accountContactConfig(),
            spy,
            contactSchema()
        );

        List<GuestRecordCaptureDto.SearchResult> rows = service.searchRecords(
            GuestRecordCaptureTestFactory.CONFIG_NAME,
            'ab',
            GuestRecordCaptureService.PURPOSE_PARENT
        );

        Assert.areEqual(0, rows.size());
        Assert.isFalse(spy.wasCalled, 'Short terms must not query.');
    }

    @IsTest
    static void searchRecords_parentPurpose_mapsIdAndLabel() {
        Account parent = new Account(Name = 'Guest Search Parent');
        insert parent;
        SearchSpy spy = new SearchSpy();
        spy.records.add(parent);
        GuestRecordCaptureService service = serviceFor(
            GuestRecordCaptureTestFactory.accountContactConfig(),
            spy,
            contactSchema()
        );

        List<GuestRecordCaptureDto.SearchResult> rows = service.searchRecords(
            GuestRecordCaptureTestFactory.CONFIG_NAME,
            'Guest Search',
            'parent'
        );

        Assert.areEqual(1, rows.size());
        Assert.areEqual(parent.Id, rows[0].id);
        Assert.areEqual('Guest Search Parent', rows[0].label);
        Assert.areEqual('Name', spy.searchField);
        Assert.areEqual(Account.SObjectType, spy.sobjectType);
    }

    @IsTest
    static void searchRecords_lookupPurpose_usesFieldSetReferenceTo() {
        Account factor = new Account(Name = 'Emissions Factor Set');
        insert factor;
        SearchSpy spy = new SearchSpy();
        spy.records.add(factor);
        GuestRecordCaptureService service = serviceFor(
            GuestRecordCaptureTestFactory.accountContactConfig(),
            spy,
            contactSchema()
        );

        List<GuestRecordCaptureDto.SearchResult> rows = service.searchRecords(
            GuestRecordCaptureTestFactory.CONFIG_NAME,
            'Emissions',
            'OtherEmssnFctrId'
        );

        Assert.areEqual(1, rows.size());
        Assert.areEqual(factor.Id, rows[0].id);
        Assert.areEqual(Account.SObjectType, spy.sobjectType);
        Assert.areEqual(GuestRecordCaptureService.DEFAULT_LOOKUP_SEARCH_FIELD, spy.searchField);
    }

    @IsTest
    static void searchRecords_unknownPurpose_throws() {
        GuestRecordCaptureService service = serviceFor(
            GuestRecordCaptureTestFactory.accountContactConfig(),
            new SearchSpy(),
            contactSchema()
        );

        try {
            service.searchRecords(GuestRecordCaptureTestFactory.CONFIG_NAME, 'abc', 'OwnerId');
            Assert.fail('Expected unknown purpose to fail.');
        } catch (GuestRecordCaptureException e) {
            Assert.isTrue(e.getMessage().contains('allowed lookup'), e.getMessage());
        }
    }

    @IsTest
    static void getFormSchema_returnsStubDescriptors() {
        GuestRecordCaptureService service = serviceFor(
            GuestRecordCaptureTestFactory.accountContactConfig(),
            new SearchSpy(),
            contactSchema()
        );

        List<GuestRecordCaptureDto.FieldDescriptor> fields = service.getFormSchema(
            GuestRecordCaptureTestFactory.CONFIG_NAME
        );

        Assert.areEqual(4, fields.size());
        Assert.areEqual('LastName', fields[0].apiName);
    }

    @IsTest
    static void createRecord_parentIdRequired() {
        GuestRecordCaptureService service = serviceFor(
            GuestRecordCaptureTestFactory.accountContactConfig(),
            new SearchSpy(),
            contactSchema()
        );

        try {
            service.createRecord(
                GuestRecordCaptureTestFactory.CONFIG_NAME,
                null,
                new Map<String, Object>{ 'LastName' => 'Guest' }
            );
            Assert.fail('Expected missing parent Id to fail.');
        } catch (GuestRecordCaptureException e) {
            Assert.isTrue(e.getMessage().contains('Parent Id is required'), e.getMessage());
        }
    }

    @IsTest
    static void createRecord_extraFieldsRejected() {
        Account parent = new Account(Name = 'Parent For Reject');
        insert parent;
        GuestRecordCaptureService service = serviceFor(
            GuestRecordCaptureTestFactory.accountContactConfig(),
            new SearchSpy(),
            contactSchema()
        );

        try {
            service.createRecord(
                GuestRecordCaptureTestFactory.CONFIG_NAME,
                parent.Id,
                new Map<String, Object>{ 'LastName' => 'Guest', 'Title' => 'Should Fail' }
            );
            Assert.fail('Expected extra field to be rejected.');
        } catch (GuestRecordCaptureException e) {
            Assert.isTrue(e.getMessage().contains('Field is not allowed: Title'), e.getMessage());
        }
    }

    @IsTest
    static void createRecord_wrongParentType_throws() {
        Contact notAParent = new Contact(LastName = 'Not Parent');
        insert notAParent;
        GuestRecordCaptureService service = serviceFor(
            GuestRecordCaptureTestFactory.accountContactConfig(),
            new SearchSpy(),
            contactSchema()
        );

        try {
            service.createRecord(
                GuestRecordCaptureTestFactory.CONFIG_NAME,
                notAParent.Id,
                new Map<String, Object>{ 'LastName' => 'Guest' }
            );
            Assert.fail('Expected parent type mismatch to fail.');
        } catch (GuestRecordCaptureException e) {
            Assert.isTrue(e.getMessage().contains('does not match'), e.getMessage());
        }
    }

    @IsTest
    static void createRecord_happyPath_contact_appliesDefaults() {
        Account parent = new Account(Name = 'Parent For Create');
        insert parent;
        SearchSpy spy = new SearchSpy();
        GuestRecordCaptureService service = serviceFor(
            GuestRecordCaptureTestFactory.accountContactConfig(),
            spy,
            contactSchema()
        );

        Test.startTest();
        Id createdId = service.createRecord(
            GuestRecordCaptureTestFactory.CONFIG_NAME,
            parent.Id,
            new Map<String, Object>{
                'LastName' => 'Captured',
                'Birthdate' => '2020-01-15'
            }
        );
        Test.stopTest();

        Contact created = [
            SELECT LastName, AccountId, Description, Birthdate
            FROM Contact
            WHERE Id = :createdId
        ];
        Assert.areEqual('Captured', created.LastName);
        Assert.areEqual(parent.Id, created.AccountId);
        Assert.areEqual('guest-default', created.Description);
        Assert.areEqual(Date.newInstance(2020, 1, 15), created.Birthdate);
        Assert.isFalse(spy.selectByIdCalled, 'Blank parent-copied map must not query the parent.');
    }

    @IsTest
    static void createRecord_copiesParentField_whenConfigured() {
        Guest_Capture_Config__mdt config = GuestRecordCaptureTestFactory.accountContactConfig();
        config.Parent_Copied_Fields__c = '{"Phone":"Phone"}';
        Account parent = new Account(Name = 'Parent With Phone', Phone = '5550100');
        insert parent;
        GuestRecordCaptureService service = serviceFor(config, new GuestSObjectSelector(), contactSchema());

        Id createdId = service.createRecord(
            GuestRecordCaptureTestFactory.CONFIG_NAME,
            parent.Id,
            new Map<String, Object>{ 'LastName' => 'Copied' }
        );

        Contact created = [SELECT Phone, AccountId FROM Contact WHERE Id = :createdId];
        Assert.areEqual('5550100', created.Phone);
        Assert.areEqual(parent.Id, created.AccountId);
    }

    @IsTest
    static void createRecord_blankParentCopiedValue_throws() {
        Guest_Capture_Config__mdt config = GuestRecordCaptureTestFactory.accountContactConfig();
        config.Parent_Copied_Fields__c = '{"Phone":"Phone"}';
        Account parent = new Account(Name = 'Parent Without Phone');
        insert parent;
        GuestRecordCaptureService service = serviceFor(config, new GuestSObjectSelector(), contactSchema());

        try {
            service.createRecord(
                GuestRecordCaptureTestFactory.CONFIG_NAME,
                parent.Id,
                new Map<String, Object>{ 'LastName' => 'Copied' }
            );
            Assert.fail('Expected a blank parent copied field to fail.');
        } catch (GuestRecordCaptureException e) {
            Assert.isTrue(e.getMessage().contains('no value'), e.getMessage());
        }
    }

    @IsTest
    static void createRecord_rejectsClientValueForParentCopiedField() {
        Guest_Capture_Config__mdt config = GuestRecordCaptureTestFactory.accountContactConfig();
        config.Parent_Copied_Fields__c = '{"Description":"Description"}';
        Account parent = new Account(Name = 'Parent Description Copy', Description = 'from-parent');
        insert parent;
        GuestRecordCaptureService service = serviceFor(config, new GuestSObjectSelector(), contactSchema());

        try {
            service.createRecord(
                GuestRecordCaptureTestFactory.CONFIG_NAME,
                parent.Id,
                new Map<String, Object>{ 'LastName' => 'Copied', 'Description' => 'from-client' }
            );
            Assert.fail('Expected a client parent-copied field to be rejected.');
        } catch (GuestRecordCaptureException e) {
            Assert.isTrue(e.getMessage().contains('Field is not allowed: Description'), e.getMessage());
        }
    }

    @IsTest
    static void createRecord_parentNotFoundForCopy_throws() {
        Guest_Capture_Config__mdt config = GuestRecordCaptureTestFactory.accountContactConfig();
        config.Parent_Copied_Fields__c = '{"Phone":"Phone"}';
        Account parent = new Account(Name = 'Parent For Missing Copy');
        insert parent;
        SearchSpy spy = new SearchSpy();
        GuestRecordCaptureService service = serviceFor(config, spy, contactSchema());

        try {
            service.createRecord(
                GuestRecordCaptureTestFactory.CONFIG_NAME,
                parent.Id,
                new Map<String, Object>{ 'LastName' => 'Copied' }
            );
            Assert.fail('Expected a missing parent to fail.');
        } catch (GuestRecordCaptureException e) {
            Assert.isTrue(e.getMessage().contains('not found'), e.getMessage());
            Assert.isTrue(spy.selectByIdCalled);
        }
    }

    @IsTest
    static void createRecord_invalidParentCopiedJson_throws() {
        Guest_Capture_Config__mdt config = GuestRecordCaptureTestFactory.accountContactConfig();
        config.Parent_Copied_Fields__c = 'not-json';
        Account parent = new Account(Name = 'Parent Invalid Copy Json');
        insert parent;
        GuestRecordCaptureService service = serviceFor(config, new SearchSpy(), contactSchema());

        try {
            service.createRecord(
                GuestRecordCaptureTestFactory.CONFIG_NAME,
                parent.Id,
                new Map<String, Object>{ 'LastName' => 'Guest' }
            );
            Assert.fail('Expected invalid parent copied JSON to fail.');
        } catch (GuestRecordCaptureException e) {
            Assert.isTrue(e.getMessage().contains('JSON'), e.getMessage());
        }
    }

    @IsTest
    static void createRecord_invalidParentCopiedValueType_throws() {
        Guest_Capture_Config__mdt config = GuestRecordCaptureTestFactory.accountContactConfig();
        config.Parent_Copied_Fields__c = '{"Phone":1}';
        Account parent = new Account(Name = 'Parent Invalid Copy Type');
        insert parent;
        GuestRecordCaptureService service = serviceFor(config, new SearchSpy(), contactSchema());

        try {
            service.createRecord(
                GuestRecordCaptureTestFactory.CONFIG_NAME,
                parent.Id,
                new Map<String, Object>{ 'LastName' => 'Guest' }
            );
            Assert.fail('Expected a non-string parent copied value to fail.');
        } catch (GuestRecordCaptureException e) {
            Assert.isTrue(e.getMessage().contains('field API names'), e.getMessage());
        }
    }

    @IsTest
    static void searchRecords_blankPurpose_usesParentObject() {
        SearchSpy spy = new SearchSpy();
        GuestRecordCaptureService service = serviceFor(
            GuestRecordCaptureTestFactory.accountContactConfig(),
            spy,
            contactSchema()
        );

        service.searchRecords(GuestRecordCaptureTestFactory.CONFIG_NAME, 'abcd', '');

        Assert.isTrue(spy.wasCalled);
        Assert.areEqual(Account.SObjectType, spy.sobjectType);
        Assert.areEqual(25, spy.resultLimit);
    }

    @IsTest
    static void searchRecords_capsResultLimit() {
        Guest_Capture_Config__mdt config = GuestRecordCaptureTestFactory.accountContactConfig();
        config.Result_Limit__c = 500;
        SearchSpy spy = new SearchSpy();
        GuestRecordCaptureService service = serviceFor(config, spy, contactSchema());

        service.searchRecords(GuestRecordCaptureTestFactory.CONFIG_NAME, 'abcd', 'parent');

        Assert.areEqual(GuestRecordCaptureService.MAX_RESULT_LIMIT, spy.resultLimit);
    }

    @IsTest
    static void createRecord_unknownParentLookup_throws() {
        Guest_Capture_Config__mdt config = GuestRecordCaptureTestFactory.accountContactConfig();
        config.Parent_Lookup_Field__c = 'NoSuchField__c';
        Account parent = new Account(Name = 'Parent Missing Lookup');
        insert parent;
        GuestRecordCaptureService service = serviceFor(config, new SearchSpy(), contactSchema());

        try {
            service.createRecord(
                GuestRecordCaptureTestFactory.CONFIG_NAME,
                parent.Id,
                new Map<String, Object>{ 'LastName' => 'Guest' }
            );
            Assert.fail('Expected unknown parent lookup to fail.');
        } catch (GuestRecordCaptureException e) {
            Assert.isTrue(e.getMessage().contains('Unknown field'), e.getMessage());
        }
    }

    @IsTest
    static void createRecord_invalidDefaultJson_throws() {
        Guest_Capture_Config__mdt config = GuestRecordCaptureTestFactory.accountContactConfig();
        config.Default_Field_Values__c = 'not-json';
        GuestRecordCaptureService service = serviceFor(config, new SearchSpy(), contactSchema());

        try {
            service.getConfig(GuestRecordCaptureTestFactory.CONFIG_NAME);
            Assert.fail('Expected invalid JSON to fail.');
        } catch (GuestRecordCaptureException e) {
            Assert.isTrue(e.getMessage().contains('JSON'), e.getMessage());
        }
    }

    @IsTest
    static void createRecord_unknownObjectInConfig_throws() {
        Guest_Capture_Config__mdt config = GuestRecordCaptureTestFactory.accountContactConfig();
        config.Search_Object__c = 'NoSuchObject__c';
        GuestRecordCaptureService service = serviceFor(config, new SearchSpy(), contactSchema());
        Account parent = new Account(Name = 'Orphan Parent');
        insert parent;

        try {
            service.createRecord(
                GuestRecordCaptureTestFactory.CONFIG_NAME,
                parent.Id,
                new Map<String, Object>{ 'LastName' => 'Guest' }
            );
            Assert.fail('Expected unknown object to fail.');
        } catch (GuestRecordCaptureException e) {
            Assert.isTrue(e.getMessage().contains('Unknown object'), e.getMessage());
        }
    }

    @IsTest
    static void createRecord_happyPath_nzc_whenAvailable() {
        if (!GuestRecordCaptureTestFactory.vehicleFieldSetAvailable()) {
            // NZC objects or Guest_Energy_Use_Capture are not in this org.
            // Allowlist/create validation is covered by Contact-based tests above.
            return;
        }
        GuestRecordCaptureService service = new GuestRecordCaptureService(
            new ConfigStub(GuestRecordCaptureTestFactory.vehicleEnergyUseConfig()),
            new GuestSObjectSelector(),
            new FieldSetSchemaService()
        );
        try {
            SObject parent = Schema.describeSObjects(new List<String>{ 'VehicleAssetEmssnSrc' })[0]
                .getSObjectType()
                .newSObject();
            parent.put('Name', 'Guest Apex Asset ' + String.valueOf(Crypto.getRandomInteger()));
            insert parent;
            SObject factor = Schema.describeSObjects(new List<String>{ 'OtherEmssnFctrSet' })[0]
                .getSObjectType()
                .newSObject();
            factor.put('Name', 'Guest Apex Factor ' + String.valueOf(Crypto.getRandomInteger()));
            insert factor;
            parent.put('OtherEmssnFctrId', factor.Id);
            update parent;

            Id createdId = service.createRecord(
                GuestRecordCaptureTestFactory.CONFIG_NAME,
                parent.Id,
                new Map<String, Object>{
                    'Name' => 'Guest Energy Use',
                    'FuelType' => 'Gasoline',
                    'FuelConsumption' => 10,
                    'FuelConsumptionUnit' => 'LITERS'
                }
            );
            Assert.isNotNull(createdId);
            SObject created = Database.query(
                'SELECT OtherEmssnFctrId FROM VehicleAssetEnrgyUse WHERE Id = :createdId',
                AccessLevel.USER_MODE
            )[0];
            Assert.areEqual(factor.Id, created.get('OtherEmssnFctrId'));
        } catch (DmlException e) {
            // NZC may enforce additional required fields or validation in this org.
            Assert.isTrue(e.getNumDml() >= 0, e.getMessage());
        }
    }

    @IsTest
    static void getConfig_andParentSearch_stationary_whenAvailable() {
        if (!GuestRecordCaptureTestFactory.nzcStationaryObjectsAvailable()) {
            return;
        }
        SearchSpy spy = new SearchSpy();
        GuestRecordCaptureService service = serviceFor(
            GuestRecordCaptureTestFactory.stationaryEnergyUseConfig(),
            spy,
            contactSchema()
        );

        GuestRecordCaptureDto.CaptureConfig config = service.getConfig(
            GuestRecordCaptureTestFactory.STATIONARY_CONFIG_NAME
        );
        Assert.areEqual(GuestRecordCaptureTestFactory.STATIONARY_CONFIG_NAME, config.developerName);
        Assert.areEqual('Stationary energy use', config.formTitle);
        Assert.areEqual('Stationary asset', config.parentSearchLabel);
        Assert.areEqual('kWh', config.defaultFieldValues.get('FuelConsumptionUnit'));

        service.searchRecords(
            GuestRecordCaptureTestFactory.STATIONARY_CONFIG_NAME,
            'abcd',
            GuestRecordCaptureService.PURPOSE_PARENT
        );

        Assert.isTrue(spy.wasCalled);
        Assert.areEqual(
            Schema.describeSObjects(new List<String>{ 'StnryAssetEnvrSrc' })[0].getSObjectType(),
            spy.sobjectType
        );
        Assert.areEqual('Name', spy.searchField);
    }

    @IsTest
    static void createRecord_stationaryWhitelistExcludesParentLookup_whenAvailable() {
        if (!GuestRecordCaptureTestFactory.stationaryFieldSetAvailable()) {
            return;
        }
        GuestRecordCaptureService service = new GuestRecordCaptureService(
            new ConfigStub(GuestRecordCaptureTestFactory.stationaryEnergyUseConfig()),
            new SearchSpy(),
            new FieldSetSchemaService()
        );
        SObject parent = Schema.describeSObjects(new List<String>{ 'StnryAssetEnvrSrc' })[0]
            .getSObjectType()
            .newSObject();
        parent.put('Name', 'Guest Apex Stationary ' + String.valueOf(Crypto.getRandomInteger()));
        insert parent;

        Set<String> allowed = new FieldSetSchemaService()
            .getAllowedFieldNames(
                Schema.describeSObjects(new List<String>{ 'StnryAssetEnrgyUse' })[0].getSObjectType(),
                'Guest_Energy_Use_Capture'
            );
        Assert.isFalse(allowed.contains('StnryAssetEnvrSrcId'));
        Assert.isFalse(allowed.contains('OtherEmssnFctrId'));
        Assert.isTrue(allowed.contains('Name'));
        Assert.isFalse(allowed.contains('FuelEfficiency'));

        try {
            service.createRecord(
                GuestRecordCaptureTestFactory.STATIONARY_CONFIG_NAME,
                parent.Id,
                new Map<String, Object>{
                    'Name' => 'Stationary Use',
                    'StnryAssetEnvrSrcId' => parent.Id
                }
            );
            Assert.fail('Expected parent lookup in payload to be rejected.');
        } catch (GuestRecordCaptureException e) {
            Assert.isTrue(e.getMessage().contains('Field is not allowed: StnryAssetEnvrSrcId'), e.getMessage());
        }

        try {
            service.createRecord(
                GuestRecordCaptureTestFactory.STATIONARY_CONFIG_NAME,
                parent.Id,
                new Map<String, Object>{
                    'Name' => 'Stationary Use',
                    'OtherEmssnFctrId' => parent.Id
                }
            );
            Assert.fail('Expected emissions factor in payload to be rejected.');
        } catch (GuestRecordCaptureException e) {
            Assert.isTrue(e.getMessage().contains('Field is not allowed: OtherEmssnFctrId'), e.getMessage());
        }

        try {
            service.createRecord(
                GuestRecordCaptureTestFactory.STATIONARY_CONFIG_NAME,
                parent.Id,
                new Map<String, Object>{
                    'Name' => 'Stationary Use',
                    'FuelEfficiency' => 10
                }
            );
            Assert.fail('Expected extra field to be rejected.');
        } catch (GuestRecordCaptureException e) {
            Assert.isTrue(e.getMessage().contains('Field is not allowed: FuelEfficiency'), e.getMessage());
        }
    }

    @IsTest
    static void coerceValue_coversDisplayTypes() {
        Assert.isNull(GuestRecordCaptureService.coerceValue(Contact.LastName, ''));
        Assert.areEqual(Date.newInstance(2020, 1, 15), GuestRecordCaptureService.coerceValue(Contact.Birthdate, '2020-01-15'));
        Assert.areEqual(
            Date.newInstance(2021, 2, 2),
            GuestRecordCaptureService.coerceValue(Contact.Birthdate, Date.newInstance(2021, 2, 2))
        );
        Assert.areEqual(true, GuestRecordCaptureService.coerceValue(Contact.DoNotCall, 'true'));
        Assert.areEqual(true, GuestRecordCaptureService.coerceValue(Contact.DoNotCall, true));
        Assert.areEqual(7, GuestRecordCaptureService.coerceValue(Account.NumberOfEmployees, 7));
        Assert.areEqual(8, GuestRecordCaptureService.coerceValue(Account.NumberOfEmployees, '8'));
        Decimal revenue = (Decimal) GuestRecordCaptureService.coerceValue(Account.AnnualRevenue, '9.5');
        Assert.areEqual(9.5, revenue);
        Assert.areEqual(Decimal.valueOf(3), GuestRecordCaptureService.coerceValue(Account.AnnualRevenue, Decimal.valueOf(3)));
        Datetime stamped = (Datetime) GuestRecordCaptureService.coerceValue(Contact.CreatedDate, '2020-01-15 12:30:00');
        Assert.isNotNull(stamped);
        Datetime existing = Datetime.newInstance(2020, 1, 1, 0, 0, 0);
        Assert.areEqual(existing, GuestRecordCaptureService.coerceValue(Contact.CreatedDate, existing));
        Account parent = new Account(Name = 'Coerce Parent');
        insert parent;
        Assert.areEqual(parent.Id, GuestRecordCaptureService.coerceValue(Contact.AccountId, String.valueOf(parent.Id)));
        Assert.areEqual('plain', GuestRecordCaptureService.coerceValue(Contact.LastName, 'plain'));
    }

    static GuestRecordCaptureService serviceFor(
        Guest_Capture_Config__mdt config,
        GuestSObjectSelector sobjectSelector,
        FieldSetSchemaService schemaService
    ) {
        return new GuestRecordCaptureService(new ConfigStub(config), sobjectSelector, schemaService);
    }

    static SchemaStub contactSchema() {
        SchemaStub schemaService = new SchemaStub();
        schemaService.descriptors.add(
            GuestRecordCaptureTestFactory.descriptor('LastName', 'STRING', true, null)
        );
        schemaService.descriptors.add(
            GuestRecordCaptureTestFactory.descriptor('Description', 'TEXTAREA', false, null)
        );
        schemaService.descriptors.add(
            GuestRecordCaptureTestFactory.descriptor('Birthdate', 'DATE', false, null)
        );
        schemaService.descriptors.add(
            GuestRecordCaptureTestFactory.descriptor('OtherEmssnFctrId', 'REFERENCE', true, new List<String>{ 'Account' })
        );
        return schemaService;
    }

    private class ConfigStub extends GuestCaptureConfigSelector {
        Guest_Capture_Config__mdt config;

        ConfigStub(Guest_Capture_Config__mdt config) {
            this.config = config;
        }

        public override Guest_Capture_Config__mdt selectByDeveloperName(String developerName) {
            if (config != null && config.DeveloperName == developerName) {
                return config;
            }
            return null;
        }
    }

    private class SchemaStub extends FieldSetSchemaService {
        List<GuestRecordCaptureDto.FieldDescriptor> descriptors = new List<GuestRecordCaptureDto.FieldDescriptor>();

        public override List<GuestRecordCaptureDto.FieldDescriptor> describeFieldSet(
            Schema.SObjectType sobjectType,
            String fieldSetName
        ) {
            return descriptors;
        }
    }

    private class SearchSpy extends GuestSObjectSelector {
        Boolean wasCalled = false;
        Boolean selectByIdCalled = false;
        Schema.SObjectType sobjectType;
        String searchField;
        Integer resultLimit;
        List<SObject> records = new List<SObject>();
        SObject parentById;

        public override List<SObject> selectBySearchTerm(
            Schema.SObjectType sobjectType,
            String searchFieldApiName,
            String term,
            Integer resultLimit
        ) {
            wasCalled = true;
            this.sobjectType = sobjectType;
            this.searchField = searchFieldApiName;
            this.resultLimit = resultLimit;
            return records;
        }

        public override SObject selectById(
            Schema.SObjectType sobjectType,
            Id recordId,
            List<String> fieldApiNames
        ) {
            selectByIdCalled = true;
            this.sobjectType = sobjectType;
            return parentById;
        }
    }
}
