/*
 * Copyright (c) 2026, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo
 * root or https://opensource.org/licenses/Apache-2.0
 */

/**
 * @description Aura-enabled DTOs for guest record capture. The client receives these
 *              shapes only; it never sends raw object API names to Apex.
 */
public with sharing class GuestRecordCaptureDto {
    /**
     * @description Runtime view of a Guest_Capture_Config__mdt row for the composer.
     */
    public class CaptureConfig {
        @AuraEnabled
        public String developerName { get; set; }
        @AuraEnabled
        public Integer minSearchLength { get; set; }
        @AuraEnabled
        public Integer resultLimit { get; set; }
        @AuraEnabled
        public Map<String, Object> defaultFieldValues { get; set; }
        @AuraEnabled
        public String formTitle { get; set; }
        @AuraEnabled
        public String parentSearchLabel { get; set; }
        @AuraEnabled
        public String submitLabel { get; set; }
    }

    /**
     * @description Typeahead row. `id` is the record Id; `label` is the configured search field.
     */
    public class SearchResult {
        @AuraEnabled
        public Id id { get; set; }
        @AuraEnabled
        public String label { get; set; }
    }

    /**
     * @description One Field Set member, including picklist options and lookup targets.
     */
    public class FieldDescriptor {
        @AuraEnabled
        public String apiName { get; set; }
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String type { get; set; }
        @AuraEnabled
        public Boolean required { get; set; }
        @AuraEnabled
        public List<PicklistOption> picklistOptions { get; set; }
        @AuraEnabled
        public List<String> referenceTo { get; set; }
    }

    /**
     * @description Active picklist entry for combobox rendering.
     */
    public class PicklistOption {
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String value { get; set; }
    }
}
