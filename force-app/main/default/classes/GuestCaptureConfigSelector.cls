/*
 * Copyright (c) 2026, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo
 * root or https://opensource.org/licenses/Apache-2.0
 */

/**
 * @description Selector for Guest_Capture_Config__mdt. Uses SOQL (not getInstance) so
 *              Default_Field_Values__c long text is not truncated at 255 characters.
 */
public inherited sharing virtual class GuestCaptureConfigSelector {
    /**
     * @description Loads one config by developer name, or null when none matches.
     * @param developerName Custom Metadata record developer name (not an object API name).
     * @return Matching config row, or null.
     */
    public virtual Guest_Capture_Config__mdt selectByDeveloperName(String developerName) {
        if (String.isBlank(developerName)) {
            return null;
        }
        List<Guest_Capture_Config__mdt> records = [
            SELECT
                Id,
                DeveloperName,
                MasterLabel,
                Search_Object__c,
                Search_Field__c,
                Target_Object__c,
                Parent_Lookup_Field__c,
                Field_Set_Name__c,
                Min_Search_Length__c,
                Result_Limit__c,
                Default_Field_Values__c,
                Form_Title__c,
                Parent_Search_Label__c,
                Submit_Label__c
            FROM Guest_Capture_Config__mdt
            WHERE DeveloperName = :developerName
            WITH USER_MODE
            LIMIT 1
        ];
        return records.isEmpty() ? null : records[0];
    }
}
