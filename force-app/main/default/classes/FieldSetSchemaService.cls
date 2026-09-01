/*
 * Copyright (c) 2026, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo
 * root or https://opensource.org/licenses/Apache-2.0
 */

/**
 * @description Maps a Field Set to FieldDescriptor DTOs (label, type, required, picklists, referenceTo).
 */
public with sharing virtual class FieldSetSchemaService {
    /**
     * @description Describes every member of a Field Set on the allowlisted target object.
     * @param sobjectType Target object token from capture config.
     * @param fieldSetName Field Set developer name from capture config.
     * @return Ordered FieldDescriptor list for the dynamic form.
     */
    public virtual List<GuestRecordCaptureDto.FieldDescriptor> describeFieldSet(
        Schema.SObjectType sobjectType,
        String fieldSetName
    ) {
        Schema.FieldSet fieldSet = requireFieldSet(sobjectType, fieldSetName);
        Map<String, Schema.SObjectField> fields = sobjectType.getDescribe().fields.getMap();
        List<GuestRecordCaptureDto.FieldDescriptor> descriptors = new List<GuestRecordCaptureDto.FieldDescriptor>();
        for (Schema.FieldSetMember member : fieldSet.getFields()) {
            String fieldPath = member.getFieldPath();
            if (String.isBlank(fieldPath) || fieldPath.contains('.')) {
                continue;
            }
            Schema.SObjectField fieldToken = fields.get(fieldPath);
            Schema.DescribeFieldResult fieldDescribe = fieldToken == null ? null : fieldToken.getDescribe();
            Boolean required = member.getRequired() || member.getDBRequired();
            descriptors.add(toDescriptor(fieldPath, member.getLabel(), required, fieldDescribe));
        }
        return descriptors;
    }

    /**
     * @description Field API names in the Field Set (create whitelist).
     * @param sobjectType Target object token from capture config.
     * @param fieldSetName Field Set developer name from capture config.
     * @return Allowlisted field API names.
     */
    public virtual Set<String> getAllowedFieldNames(Schema.SObjectType sobjectType, String fieldSetName) {
        Set<String> names = new Set<String>();
        for (GuestRecordCaptureDto.FieldDescriptor descriptor : describeFieldSet(sobjectType, fieldSetName)) {
            if (!String.isBlank(descriptor.apiName)) {
                names.add(descriptor.apiName);
            }
        }
        return names;
    }

    /**
     * @description Builds a FieldDescriptor from describe data. Test-visible for coverage without a Field Set.
     * @param apiName Field API name.
     * @param label Field label.
     * @param required Field Set or database required flag.
     * @param fieldDescribe Optional describe; picklists and references are filled when present.
     * @return Populated descriptor.
     */
    @TestVisible
    static GuestRecordCaptureDto.FieldDescriptor toDescriptor(
        String apiName,
        String label,
        Boolean required,
        Schema.DescribeFieldResult fieldDescribe
    ) {
        GuestRecordCaptureDto.FieldDescriptor descriptor = new GuestRecordCaptureDto.FieldDescriptor();
        descriptor.apiName = apiName;
        descriptor.label = label;
        descriptor.required = required == true;
        descriptor.picklistOptions = new List<GuestRecordCaptureDto.PicklistOption>();
        descriptor.referenceTo = new List<String>();
        if (fieldDescribe == null) {
            descriptor.type = 'STRING';
            return descriptor;
        }
        descriptor.type = String.valueOf(fieldDescribe.getType());
        Schema.DisplayType displayType = fieldDescribe.getType();
        if (displayType == Schema.DisplayType.PICKLIST || displayType == Schema.DisplayType.MULTIPICKLIST) {
            for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                if (!entry.isActive()) {
                    continue;
                }
                GuestRecordCaptureDto.PicklistOption option = new GuestRecordCaptureDto.PicklistOption();
                option.label = entry.getLabel();
                option.value = entry.getValue();
                descriptor.picklistOptions.add(option);
            }
        }
        for (Schema.SObjectType referencedType : fieldDescribe.getReferenceTo()) {
            descriptor.referenceTo.add(referencedType.getDescribe().getName());
        }
        return descriptor;
    }

    private static Schema.FieldSet requireFieldSet(Schema.SObjectType sobjectType, String fieldSetName) {
        if (sobjectType == null) {
            throw new GuestRecordCaptureException('A target object is required.');
        }
        if (String.isBlank(fieldSetName)) {
            throw new GuestRecordCaptureException('A Field Set name is required.');
        }
        Schema.FieldSet fieldSet = sobjectType.getDescribe().fieldSets.getMap().get(fieldSetName);
        if (fieldSet == null) {
            throw new GuestRecordCaptureException('Unknown Field Set in capture config.');
        }
        return fieldSet;
    }
}
