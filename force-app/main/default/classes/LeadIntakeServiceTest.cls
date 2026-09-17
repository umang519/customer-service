@isTest
private with sharing class LeadIntakeServiceTest {
    @isTest
    static void testCreateLeadSuccess() {
        LeadIntakeService.LeadRequest request = new LeadIntakeService.LeadRequest();
        request.firstName = 'Test';
        request.lastName = 'Lead';
        request.company = 'Test Co';
        request.email = 'test@example.com';
        request.phone = '555-0300';
        request.industry = 'Technology';
        request.region = 'North America';
        request.leadSource = 'Web';

        Test.startTest();
        LeadIntakeService.LeadResponse response = LeadIntakeService.createLead(request);
        Test.stopTest();

        System.assert(response.success, 'Response should indicate success');
        System.assert(response.leadId != null, 'Lead ID should be returned');

        Lead createdLead = [
            SELECT FirstName, LastName, Company, Email, Phone, Industry, Region__c, LeadSource
            FROM Lead
            WHERE Id = :response.leadId
            WITH SECURITY_ENFORCED
        ];
        System.assertEquals('Test', createdLead.FirstName, 'First name should match');
        System.assertEquals('Test Co', createdLead.Company, 'Company should match');
        System.assertEquals('North America', createdLead.Region__c, 'Region should match');
    }

    @isTest
    static void testCreateLeadValidationFailure() {
        LeadIntakeService.LeadRequest request = new LeadIntakeService.LeadRequest();
        request.lastName = 'Lead';

        Test.startTest();
        LeadIntakeService.LeadResponse response = LeadIntakeService.createLead(request);
        Test.stopTest();

        System.assert(!response.success, 'Response should indicate failure');
        System.assert(response.errorMessage != null, 'Error message should be returned');
    }
}