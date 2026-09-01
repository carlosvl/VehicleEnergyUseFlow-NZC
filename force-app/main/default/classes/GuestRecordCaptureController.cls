/*
 * Copyright (c) 2026, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo
 * root or https://opensource.org/licenses/Apache-2.0
 */

/**
 * @description Thin Aura-enabled façade for guest record capture. The client may pass only a
 *              Custom Metadata developer name, never raw object API names.
 */
public with sharing class GuestRecordCaptureController {
    /**
     * @description Loads composer config for a capture config developer name.
     * @param configName Guest_Capture_Config__mdt developer name.
     * @return CaptureConfig DTO.
     */
    @AuraEnabled(cacheable=true)
    public static GuestRecordCaptureDto.CaptureConfig getConfig(String configName) {
        try {
            return GuestRecordCaptureService.newInstance().getConfig(configName);
        } catch (Exception e) {
            throw asAura(e);
        }
    }

    /**
     * @description Typeahead search against the allowlisted parent object or a Field Set lookup.
     * @param configName Guest_Capture_Config__mdt developer name.
     * @param term Search text.
     * @param purpose `parent` or a Field Set reference field API name (for example OtherEmssnFctrId).
     * @return SearchResult rows.
     */
    @AuraEnabled(cacheable=true)
    public static List<GuestRecordCaptureDto.SearchResult> searchRecords(
        String configName,
        String term,
        String purpose
    ) {
        try {
            return GuestRecordCaptureService.newInstance().searchRecords(configName, term, purpose);
        } catch (Exception e) {
            throw asAura(e);
        }
    }

    /**
     * @description Field Set schema for the dynamic create form.
     * @param configName Guest_Capture_Config__mdt developer name.
     * @return FieldDescriptor list.
     */
    @AuraEnabled(cacheable=true)
    public static List<GuestRecordCaptureDto.FieldDescriptor> getFormSchema(String configName) {
        try {
            return GuestRecordCaptureService.newInstance().getFormSchema(configName);
        } catch (Exception e) {
            throw asAura(e);
        }
    }

    /**
     * @description Creates a target record. Extra Field Set keys are rejected; parent lookup comes from parentId.
     * @param configName Guest_Capture_Config__mdt developer name.
     * @param parentId Selected parent record Id.
     * @param values Field Set value map.
     * @return Id of the inserted record.
     */
    @AuraEnabled
    public static Id createRecord(String configName, Id parentId, Map<String, Object> values) {
        try {
            return GuestRecordCaptureService.newInstance().createRecord(configName, parentId, values);
        } catch (Exception e) {
            throw asAura(e);
        }
    }

    private static AuraHandledException asAura(Exception e) {
        String message = e.getMessage();
        AuraHandledException auraException = new AuraHandledException(message);
        auraException.setMessage(message);
        return auraException;
    }
}
