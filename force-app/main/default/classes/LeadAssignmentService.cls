public with sharing class LeadAssignmentService {
    @InvocableMethod(
        label='Assign Lead Owners'
        description='Assigns lead owners based on region and industry using Lead Assignment Mapping records.'
    )
    public static void assignLeadOwners(List<Lead> leads) {
        if (leads == null || leads.isEmpty()) {
            return;
        }

        Set<String> regions = new Set<String>();
        Set<String> industries = new Set<String>();
        for (Lead ld : leads) {
            if (String.isNotBlank(ld.Region__c)) {
                regions.add(ld.Region__c.toLowerCase());
            }
            if (String.isNotBlank(ld.Industry)) {
                industries.add(ld.Industry.toLowerCase());
            }
        }

        if (regions.isEmpty() && industries.isEmpty()) {
            return;
        }

        List<Lead_Assignment_Mapping__c> mappings = [
            SELECT Region__c, Industry__c, Assigned_Rep__c
            FROM Lead_Assignment_Mapping__c
            WHERE Region__c IN :regions
               OR Industry__c IN :industries
               OR (Region__c = NULL AND Industry__c = NULL)
            WITH SECURITY_ENFORCED
        ];

        Map<String, Id> exactMatchMap = new Map<String, Id>();
        Map<String, Id> regionFallbackMap = new Map<String, Id>();
        Map<String, Id> industryFallbackMap = new Map<String, Id>();
        Id defaultOwnerId = null;

        for (Lead_Assignment_Mapping__c mapping : mappings) {
            String region = String.isNotBlank(mapping.Region__c) ? mapping.Region__c.toLowerCase() : '';
            String industry = String.isNotBlank(mapping.Industry__c) ? mapping.Industry__c.toLowerCase() : '';

            if (String.isBlank(region) && String.isBlank(industry)) {
                defaultOwnerId = mapping.Assigned_Rep__c;
                continue;
            }

            String key = region + '|' + industry;
            exactMatchMap.put(key, mapping.Assigned_Rep__c);

            if (String.isNotBlank(region)) {
                regionFallbackMap.put(region, mapping.Assigned_Rep__c);
            }
            if (String.isNotBlank(industry)) {
                industryFallbackMap.put(industry, mapping.Assigned_Rep__c);
            }
        }

        for (Lead ld : leads) {
            String region = String.isNotBlank(ld.Region__c) ? ld.Region__c.toLowerCase() : '';
            String industry = String.isNotBlank(ld.Industry) ? ld.Industry.toLowerCase() : '';
            String exactKey = region + '|' + industry;

            if (exactMatchMap.containsKey(exactKey)) {
                ld.OwnerId = exactMatchMap.get(exactKey);
            } else if (String.isNotBlank(region) && regionFallbackMap.containsKey(region)) {
                ld.OwnerId = regionFallbackMap.get(region);
            } else if (String.isNotBlank(industry) && industryFallbackMap.containsKey(industry)) {
                ld.OwnerId = industryFallbackMap.get(industry);
            } else if (defaultOwnerId != null) {
                ld.OwnerId = defaultOwnerId;
            }
        }
    }
}