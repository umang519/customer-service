@isTest
private with sharing class LeadAssignmentServiceTest {
    @TestSetup
    static void setupTestData() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() WITH SECURITY_ENFORCED];

        List<Lead_Assignment_Mapping__c> mappings = new List<Lead_Assignment_Mapping__c>();
        mappings.add(new Lead_Assignment_Mapping__c(
            Name = 'NA Technology',
            Region__c = 'North America',
            Industry__c = 'Technology',
            Assigned_Rep__c = currentUser.Id
        ));
        mappings.add(new Lead_Assignment_Mapping__c(
            Name = 'NA Fallback',
            Region__c = 'North America',
            Assigned_Rep__c = currentUser.Id
        ));
        mappings.add(new Lead_Assignment_Mapping__c(
            Name = 'Technology Fallback',
            Industry__c = 'Technology',
            Assigned_Rep__c = currentUser.Id
        ));
        mappings.add(new Lead_Assignment_Mapping__c(
            Name = 'Default',
            Assigned_Rep__c = currentUser.Id
        ));
        insert mappings;
    }

    @isTest
    static void testSingleLeadAssignmentExactMatch() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Co',
            Email = 'test@example.com',
            Phone = '555-0100',
            Industry = 'Technology',
            Region__c = 'North America'
        );

        Test.startTest();
        LeadAssignmentService.assignLeadOwners(new List<Lead>{testLead});
        Test.stopTest();

        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() WITH SECURITY_ENFORCED];
        System.assertEquals(currentUser.Id, testLead.OwnerId, 'Lead should be assigned to mapped rep');
    }

    @isTest
    static void testBulkLeadAssignment() {
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 200; i++) {
            leads.add(new Lead(
                FirstName = 'Test',
                LastName = 'Lead ' + i,
                Company = 'Test Co',
                Email = 'test' + i + '@example.com',
                Phone = '555-0100',
                Industry = 'Technology',
                Region__c = 'North America'
            ));
        }

        Test.startTest();
        LeadAssignmentService.assignLeadOwners(leads);
        Test.stopTest();

        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() WITH SECURITY_ENFORCED];
        for (Lead ld : leads) {
            System.assertEquals(currentUser.Id, ld.OwnerId, 'All leads should be assigned to mapped rep');
        }
    }

    @isTest
    static void testNoMatchFallback() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Co',
            Email = 'test@example.com',
            Phone = '555-0100',
            Industry = 'Healthcare',
            Region__c = 'Europe'
        );

        Test.startTest();
        LeadAssignmentService.assignLeadOwners(new List<Lead>{testLead});
        Test.stopTest();

        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() WITH SECURITY_ENFORCED];
        System.assertEquals(currentUser.Id, testLead.OwnerId, 'Lead with no exact match should fall back to default mapping');
    }

    @isTest
    static void testMixedRegionIndustry() {
        Lead naTech = new Lead(
            FirstName = 'A',
            LastName = 'A',
            Company = 'A',
            Email = 'a@a.com',
            Phone = '1',
            Industry = 'Technology',
            Region__c = 'North America'
        );
        Lead euHealth = new Lead(
            FirstName = 'B',
            LastName = 'B',
            Company = 'B',
            Email = 'b@b.com',
            Phone = '2',
            Industry = 'Healthcare',
            Region__c = 'Europe'
        );

        Test.startTest();
        LeadAssignmentService.assignLeadOwners(new List<Lead>{naTech, euHealth});
        Test.stopTest();

        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() WITH SECURITY_ENFORCED];
        System.assertEquals(currentUser.Id, naTech.OwnerId, 'NA Technology lead should be assigned');
        System.assertEquals(currentUser.Id, euHealth.OwnerId, 'Europe Healthcare lead should fall back to default');
    }
}