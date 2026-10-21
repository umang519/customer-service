@isTest
public with sharing class QuickLeadSearchControllerTest {

    @testSetup
    static void setupTestData() {
        List<Lead> leads = new List<Lead>();
        leads.add(new Lead(
            LastName = 'Smith',
            Company = 'Test Company',
            Email = 'smith@example.com',
            Status = 'Open - Not Contacted'
        ));
        leads.add(new Lead(
            LastName = 'Johnson',
            Company = 'Acme Inc',
            Email = 'johnson@example.com',
            Status = 'Open - Not Contacted'
        ));
        leads.add(new Lead(
            LastName = 'Williams',
            Company = 'Global Corp',
            Email = 'williams@example.com',
            Status = 'Open - Not Contacted'
        ));
        insert leads;
    }

    @isTest
    static void searchLeads_TermTooShort_ThrowsException() {
        Boolean exceptionThrown = false;
        try {
            QuickLeadSearchController.searchLeads('ab');
        } catch (AuraHandledException ex) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Should throw an exception when search term is shorter than 3 characters');
    }

    @isTest
    static void searchLeads_PartialNameMatch_ReturnsMatchingLeads() {
        Lead expectedLead = [SELECT Name FROM Lead WHERE Email = 'smith@example.com' LIMIT 1];
        List<Lead> results = QuickLeadSearchController.searchLeads('Smith');
        System.assert(!results.isEmpty(), 'Should return results for partial name match');
        System.assertEquals(expectedLead.Name, results[0].Name, 'Returned lead should match the searched name');
    }

    @isTest
    static void searchLeads_PartialCompanyMatch_ReturnsMatchingLeads() {
        Lead expectedLead = [SELECT Company FROM Lead WHERE Company LIKE '%Company%' LIMIT 1];
        List<Lead> results = QuickLeadSearchController.searchLeads('Company');
        System.assert(!results.isEmpty(), 'Should return results for partial company match');
        System.assertEquals(expectedLead.Company, results[0].Company, 'Returned lead should match the searched company');
    }

    @isTest
    static void searchLeads_ExactEmailMatch_ReturnsMatchingLead() {
        Lead expectedLead = [SELECT Email FROM Lead WHERE Email = 'smith@example.com' LIMIT 1];
        List<Lead> results = QuickLeadSearchController.searchLeads(expectedLead.Email);
        System.assertEquals(1, results.size(), 'Should return exactly one lead for exact email match');
        System.assertEquals(expectedLead.Email, results[0].Email, 'Returned lead should match the searched email');
    }

    @isTest
    static void searchLeads_NoMatch_ReturnsEmptyList() {
        List<Lead> results = QuickLeadSearchController.searchLeads('XYZNOmatch12345');
        System.assert(results.isEmpty(), 'Should return an empty list when no leads match');
    }

    @isTest
    static void searchLeads_BulkSearch_ReturnsResults() {
        List<Lead> bulkLeads = new List<Lead>();
        for (Integer i = 0; i < 200; i++) {
            bulkLeads.add(new Lead(
                LastName = 'Bulk' + i,
                Company = 'BulkCompanyUnique',
                Status = 'Open - Not Contacted'
            ));
        }

        Test.startTest();
        insert bulkLeads;
        List<Lead> results = QuickLeadSearchController.searchLeads('BulkCompanyUnique');
        Test.stopTest();

        System.assertEquals(50, results.size(), 'Should return the maximum number of results allowed by the query limit');
    }
}