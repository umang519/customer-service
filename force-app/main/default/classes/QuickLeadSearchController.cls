public with sharing class QuickLeadSearchController {
    @AuraEnabled(cacheable=true)
    public static List<Lead> searchLeads(String searchTerm) {
        if (String.isBlank(searchTerm) || searchTerm.length() < 3) {
            throw new AuraHandledException('Search term must be at least 3 characters.');
        }

        String likeTerm = '%' + searchTerm + '%';

        return [
            SELECT Id, Name, Company, Email, Status, Region__c, Industry
            FROM Lead
            WHERE (Name LIKE :likeTerm OR Company LIKE :likeTerm OR Email = :searchTerm)
            WITH SECURITY_ENFORCED
            ORDER BY Name
            LIMIT 50
        ];
    }
}