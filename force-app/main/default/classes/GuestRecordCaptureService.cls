/*
 * Copyright (c) 2026, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo
 * root or https://opensource.org/licenses/Apache-2.0
 */

/**
 * @description Orchestrates guest record capture: config allowlist, USER_MODE search,
 *              Field Set schema, and create with a Field Set whitelist.
 */
public with sharing class GuestRecordCaptureService {
    public static final String PURPOSE_PARENT = 'parent';

    @TestVisible
    static final Integer DEFAULT_MIN_SEARCH_LENGTH = 3;
    @TestVisible
    static final Integer DEFAULT_RESULT_LIMIT = 25;
    @TestVisible
    static final Integer MAX_RESULT_LIMIT = 200;
    @TestVisible
    static final String DEFAULT_LOOKUP_SEARCH_FIELD = 'Name';

    private final GuestCaptureConfigSelector configSelector;
    private final GuestSObjectSelector sobjectSelector;
    private final FieldSetSchemaService fieldSetSchemaService;

    /**
     * @description Production factory. Resolves selector and schema collaborators.
     * @return Service wired to concrete collaborators.
     */
    public static GuestRecordCaptureService newInstance() {
        return new GuestRecordCaptureService(
            new GuestCaptureConfigSelector(),
            new GuestSObjectSelector(),
            new FieldSetSchemaService()
        );
    }

    /**
     * @description Constructor for production and tests (stub collaborators).
     * @param configSelector Guest capture config selector.
     * @param sobjectSelector Allowlisted SObject search selector.
     * @param fieldSetSchemaService Field Set describe service.
     */
    public GuestRecordCaptureService(
        GuestCaptureConfigSelector configSelector,
        GuestSObjectSelector sobjectSelector,
        FieldSetSchemaService fieldSetSchemaService
    ) {
        this.configSelector = configSelector;
        this.sobjectSelector = sobjectSelector;
        this.fieldSetSchemaService = fieldSetSchemaService;
    }

    /**
     * @description Returns composer-facing config for a Custom Metadata developer name.
     * @param configName Guest_Capture_Config__mdt developer name.
     * @return CaptureConfig DTO.
     */
    public GuestRecordCaptureDto.CaptureConfig getConfig(String configName) {
        Guest_Capture_Config__mdt config = requireConfig(configName);
        GuestRecordCaptureDto.CaptureConfig dto = new GuestRecordCaptureDto.CaptureConfig();
        dto.developerName = config.DeveloperName;
        dto.minSearchLength = toMinSearchLength(config);
        dto.resultLimit = toResultLimit(config);
        dto.defaultFieldValues = parseDefaultFieldValues(config.Default_Field_Values__c);
        dto.formTitle = config.Form_Title__c;
        dto.parentSearchLabel = config.Parent_Search_Label__c;
        dto.submitLabel = config.Submit_Label__c;
        return dto;
    }

    /**
     * @description Typeahead search. Purpose `parent` uses the config search object;
     *              any other purpose must be a Field Set lookup field API name.
     * @param configName Guest_Capture_Config__mdt developer name.
     * @param term Search text.
     * @param purpose `parent` or a Field Set reference field API name.
     * @return SearchResult rows, or an empty list when the term is shorter than the configured minimum.
     */
    public List<GuestRecordCaptureDto.SearchResult> searchRecords(String configName, String term, String purpose) {
        Guest_Capture_Config__mdt config = requireConfig(configName);
        String trimmedTerm = term == null ? '' : term.trim();
        if (trimmedTerm.length() < toMinSearchLength(config)) {
            return new List<GuestRecordCaptureDto.SearchResult>();
        }
        Schema.SObjectType searchType;
        String searchField;
        if (String.isBlank(purpose) || PURPOSE_PARENT.equalsIgnoreCase(purpose)) {
            searchType = requireSObjectType(config.Search_Object__c);
            searchField = config.Search_Field__c;
        } else {
            LookupSearchTarget lookupTarget = resolveLookupSearch(config, purpose);
            searchType = lookupTarget.sobjectType;
            searchField = lookupTarget.searchField;
        }
        List<SObject> records = sobjectSelector.selectBySearchTerm(
            searchType,
            searchField,
            trimmedTerm,
            toResultLimit(config)
        );
        return toSearchResults(records, searchField);
    }

    /**
     * @description Field Set members as FieldDescriptors for the dynamic form.
     * @param configName Guest_Capture_Config__mdt developer name.
     * @return FieldDescriptor list.
     */
    public List<GuestRecordCaptureDto.FieldDescriptor> getFormSchema(String configName) {
        Guest_Capture_Config__mdt config = requireConfig(configName);
        Schema.SObjectType targetType = requireSObjectType(config.Target_Object__c);
        return fieldSetSchemaService.describeFieldSet(targetType, config.Field_Set_Name__c);
    }

    /**
     * @description Inserts one target record. Extra keys are rejected; the parent lookup is set from parentId.
     * @param configName Guest_Capture_Config__mdt developer name.
     * @param parentId Selected parent record Id (required).
     * @param values Field Set value map from the client.
     * @return Id of the inserted record.
     */
    public Id createRecord(String configName, Id parentId, Map<String, Object> values) {
        Guest_Capture_Config__mdt config = requireConfig(configName);
        if (parentId == null) {
            throw new GuestRecordCaptureException('Parent Id is required.');
        }
        Schema.SObjectType searchType = requireSObjectType(config.Search_Object__c);
        if (parentId.getSobjectType() != searchType) {
            throw new GuestRecordCaptureException('Parent Id does not match the configured search object.');
        }
        Schema.SObjectType targetType = requireSObjectType(config.Target_Object__c);
        List<GuestRecordCaptureDto.FieldDescriptor> descriptors = fieldSetSchemaService.describeFieldSet(
            targetType,
            config.Field_Set_Name__c
        );
        Set<String> allowedFields = toAllowedFieldNames(descriptors);
        Map<String, Object> incoming = values == null ? new Map<String, Object>() : new Map<String, Object>(values);
        rejectUnknownKeys(incoming.keySet(), allowedFields);
        applyDefaults(incoming, allowedFields, parseDefaultFieldValues(config.Default_Field_Values__c));
        SObject record = targetType.newSObject();
        Map<String, Schema.SObjectField> fieldTokens = targetType.getDescribe().fields.getMap();
        for (String fieldName : incoming.keySet()) {
            Schema.SObjectField fieldToken = fieldTokens.get(fieldName);
            if (fieldToken == null) {
                continue;
            }
            record.put(fieldToken, coerceValue(fieldToken, incoming.get(fieldName)));
        }
        Schema.SObjectField parentField = requireField(targetType, config.Parent_Lookup_Field__c);
        record.put(parentField, parentId);
        Database.insert(record, AccessLevel.USER_MODE);
        return record.Id;
    }

    private Guest_Capture_Config__mdt requireConfig(String configName) {
        if (String.isBlank(configName)) {
            throw new GuestRecordCaptureException('A capture config name is required.');
        }
        Guest_Capture_Config__mdt config = configSelector.selectByDeveloperName(configName);
        if (config == null) {
            throw new GuestRecordCaptureException('Unknown capture config.');
        }
        return config;
    }

    private static Schema.SObjectType requireSObjectType(String apiName) {
        if (String.isBlank(apiName)) {
            throw new GuestRecordCaptureException('An object API name is required in capture config.');
        }
        try {
            List<Schema.DescribeSObjectResult> describes = Schema.describeSObjects(new List<String>{ apiName });
            if (describes.isEmpty() || describes[0] == null) {
                throw new GuestRecordCaptureException('Unknown object in capture config.');
            }
            return describes[0].getSObjectType();
        } catch (GuestRecordCaptureException e) {
            throw e;
        } catch (Exception e) {
            throw new GuestRecordCaptureException('Unknown object in capture config.');
        }
    }

    private static Schema.SObjectField requireField(Schema.SObjectType sobjectType, String fieldApiName) {
        if (String.isBlank(fieldApiName)) {
            throw new GuestRecordCaptureException('A field API name is required in capture config.');
        }
        Schema.SObjectField fieldToken = sobjectType.getDescribe().fields.getMap().get(fieldApiName);
        if (fieldToken == null) {
            throw new GuestRecordCaptureException('Unknown field in capture config.');
        }
        return fieldToken;
    }

    private LookupSearchTarget resolveLookupSearch(Guest_Capture_Config__mdt config, String purpose) {
        Schema.SObjectType targetType = requireSObjectType(config.Target_Object__c);
        GuestRecordCaptureDto.FieldDescriptor match;
        for (GuestRecordCaptureDto.FieldDescriptor descriptor : fieldSetSchemaService.describeFieldSet(
            targetType,
            config.Field_Set_Name__c
        )) {
            if (descriptor.apiName != null && descriptor.apiName.equalsIgnoreCase(purpose)) {
                match = descriptor;
                break;
            }
        }
        if (match == null || match.referenceTo == null || match.referenceTo.isEmpty()) {
            throw new GuestRecordCaptureException('Search purpose is not an allowed lookup field.');
        }
        LookupSearchTarget target = new LookupSearchTarget();
        target.sobjectType = requireSObjectType(match.referenceTo[0]);
        target.searchField = DEFAULT_LOOKUP_SEARCH_FIELD;
        return target;
    }

    private static List<GuestRecordCaptureDto.SearchResult> toSearchResults(List<SObject> records, String searchField) {
        List<GuestRecordCaptureDto.SearchResult> results = new List<GuestRecordCaptureDto.SearchResult>();
        if (records == null) {
            return results;
        }
        for (SObject record : records) {
            GuestRecordCaptureDto.SearchResult row = new GuestRecordCaptureDto.SearchResult();
            row.id = record.Id;
            Object labelValue = record.get(searchField);
            row.label = labelValue == null ? '' : String.valueOf(labelValue);
            results.add(row);
        }
        return results;
    }

    private static Set<String> toAllowedFieldNames(List<GuestRecordCaptureDto.FieldDescriptor> descriptors) {
        Set<String> names = new Set<String>();
        for (GuestRecordCaptureDto.FieldDescriptor descriptor : descriptors) {
            if (!String.isBlank(descriptor.apiName)) {
                names.add(descriptor.apiName);
            }
        }
        return names;
    }

    private static void rejectUnknownKeys(Set<String> incomingKeys, Set<String> allowedFields) {
        for (String key : incomingKeys) {
            if (!containsIgnoreCase(allowedFields, key)) {
                throw new GuestRecordCaptureException('Field is not allowed: ' + key);
            }
        }
    }

    private static Boolean containsIgnoreCase(Set<String> allowedFields, String key) {
        if (allowedFields.contains(key)) {
            return true;
        }
        for (String allowed : allowedFields) {
            if (allowed != null && allowed.equalsIgnoreCase(key)) {
                return true;
            }
        }
        return false;
    }

    private static void applyDefaults(
        Map<String, Object> incoming,
        Set<String> allowedFields,
        Map<String, Object> defaults
    ) {
        if (defaults == null || defaults.isEmpty()) {
            return;
        }
        for (String defaultKey : defaults.keySet()) {
            if (!containsIgnoreCase(allowedFields, defaultKey)) {
                continue;
            }
            if (isBlankValue(incoming.get(defaultKey))) {
                incoming.put(defaultKey, defaults.get(defaultKey));
            }
        }
    }

    private static Boolean isBlankValue(Object rawValue) {
        if (rawValue == null) {
            return true;
        }
        return String.isBlank(String.valueOf(rawValue));
    }

    private static Map<String, Object> parseDefaultFieldValues(String jsonMap) {
        if (String.isBlank(jsonMap)) {
            return new Map<String, Object>();
        }
        try {
            Object parsed = JSON.deserializeUntyped(jsonMap);
            if (parsed instanceof Map<String, Object>) {
                return (Map<String, Object>) parsed;
            }
            throw new GuestRecordCaptureException('Default field values must be a JSON object.');
        } catch (GuestRecordCaptureException e) {
            throw e;
        } catch (Exception e) {
            throw new GuestRecordCaptureException('Default field values must be valid JSON.');
        }
    }

    private static Integer toMinSearchLength(Guest_Capture_Config__mdt config) {
        if (config.Min_Search_Length__c == null || config.Min_Search_Length__c < 1) {
            return DEFAULT_MIN_SEARCH_LENGTH;
        }
        return Integer.valueOf(config.Min_Search_Length__c);
    }

    private static Integer toResultLimit(Guest_Capture_Config__mdt config) {
        Integer resultLimit = DEFAULT_RESULT_LIMIT;
        if (config.Result_Limit__c != null && config.Result_Limit__c >= 1) {
            resultLimit = Integer.valueOf(config.Result_Limit__c);
        }
        if (resultLimit > MAX_RESULT_LIMIT) {
            return MAX_RESULT_LIMIT;
        }
        return resultLimit;
    }

    @TestVisible
    static Object coerceValue(Schema.SObjectField fieldToken, Object rawValue) {
        if (rawValue == null || isBlankValue(rawValue)) {
            return null;
        }
        Schema.DisplayType displayType = fieldToken.getDescribe().getType();
        switch on displayType {
            when DATE {
                if (rawValue instanceof Date) {
                    return rawValue;
                }
                return Date.valueOf(String.valueOf(rawValue));
            }
            when DATETIME {
                if (rawValue instanceof Datetime) {
                    return rawValue;
                }
                return Datetime.valueOf(String.valueOf(rawValue));
            }
            when BOOLEAN {
                if (rawValue instanceof Boolean) {
                    return rawValue;
                }
                return Boolean.valueOf(String.valueOf(rawValue));
            }
            when INTEGER {
                if (rawValue instanceof Integer) {
                    return rawValue;
                }
                return Integer.valueOf(String.valueOf(rawValue));
            }
            when DOUBLE, CURRENCY, PERCENT {
                if (rawValue instanceof Decimal) {
                    return rawValue;
                }
                return Decimal.valueOf(String.valueOf(rawValue));
            }
            when ID, REFERENCE {
                return Id.valueOf(String.valueOf(rawValue));
            }
            when else {
                return rawValue;
            }
        }
    }

    private class LookupSearchTarget {
        Schema.SObjectType sobjectType;
        String searchField;
    }
}
