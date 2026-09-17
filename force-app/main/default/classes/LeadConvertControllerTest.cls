@isTest
private with sharing class LeadConvertControllerTest {
    @TestSetup
    static void setupTestData() {
        LeadStatus openStatus = [
            SELECT MasterLabel
            FROM LeadStatus
            WHERE IsConverted = false
            LIMIT 1
            WITH SECURITY_ENFORCED
        ];

        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Convert',
            Company = 'Test Co',
            Email = 'convert@example.com',
            Phone = '555-0200',
            Industry = 'Technology',
            Region__c = 'North America',
            Status = openStatus.MasterLabel
        );
        insert testLead;
    }

    @isTest
    static void testConvertLeadWithOpportunity() {
        Lead testLead = [SELECT Id FROM Lead WHERE LastName = 'Convert' WITH SECURITY_ENFORCED];

        Test.startTest();
        LeadConvertController.ConvertResult result = LeadConvertController.convertLead(testLead.Id, 'Test Opp');
        Test.stopTest();

        System.assert(result.isSuccess, 'Lead conversion should succeed');

        Lead convertedLead = [
            SELECT IsConverted, ConvertedAccountId, ConvertedContactId, ConvertedOpportunityId
            FROM Lead
            WHERE Id = :testLead.Id
            WITH SECURITY_ENFORCED
        ];
        System.assert(convertedLead.IsConverted, 'Lead should be marked converted');
        System.assert(convertedLead.ConvertedAccountId != null, 'Account should be created');
        System.assert(convertedLead.ConvertedContactId != null, 'Contact should be created');
        System.assert(convertedLead.ConvertedOpportunityId != null, 'Opportunity should be created');
    }

    @isTest
    static void testConvertLeadWithoutOpportunity() {
        Lead testLead = [SELECT Id FROM Lead WHERE LastName = 'Convert' WITH SECURITY_ENFORCED];

        Test.startTest();
        LeadConvertController.ConvertResult result = LeadConvertController.convertLead(testLead.Id, '');
        Test.stopTest();

        System.assert(result.isSuccess, 'Lead conversion should succeed');

        Lead convertedLead = [
            SELECT IsConverted, ConvertedOpportunityId
            FROM Lead
            WHERE Id = :testLead.Id
            WITH SECURITY_ENFORCED
        ];
        System.assert(convertedLead.IsConverted, 'Lead should be marked converted');
        System.assertEquals(null, convertedLead.ConvertedOpportunityId, 'No opportunity should be created');
    }
}