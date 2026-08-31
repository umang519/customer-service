@isTest
private class LeadFollowUpControllerTest {

    @TestSetup
    static void setup() {
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 210; i++) {
            leads.add(new Lead(LastName = 'Test ' + i, Company = 'Test Co'));
        }

        Test.startTest();
        insert leads;
        Test.stopTest();
    }

    @isTest
    static void testAssignLeadToCurrentUser() {
        Lead testLead = [SELECT Id, OwnerId FROM Lead LIMIT 1];
        List<Id> leadIds = new List<Id>{ testLead.Id };

        Test.startTest();
        List<Lead> result = LeadFollowUpController.assignLeadToCurrentUser(leadIds);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'One lead should be returned.');
        System.assertEquals(UserInfo.getUserId(), result[0].OwnerId, 'Lead owner should be the current user.');
    }

    @isTest
    static void testUpdateLeadStatus() {
        Lead testLead = [SELECT Id, Status FROM Lead LIMIT 1];
        List<Id> leadIds = new List<Id>{ testLead.Id };

        Test.startTest();
        List<Lead> result = LeadFollowUpController.updateLeadStatus(leadIds, 'Working - Contacted');
        Test.stopTest();

        System.assertEquals(1, result.size(), 'One lead should be returned.');
        System.assertEquals('Working - Contacted', result[0].Status, 'Lead status should be updated.');
    }

    @isTest
    static void testCreateFollowUpTask() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        List<Id> leadIds = new List<Id>{ testLead.Id };

        Test.startTest();
        List<Task> result = LeadFollowUpController.createFollowUpTask(leadIds);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'One task should be created.');
        System.assertEquals(testLead.Id, result[0].WhoId, 'Task should be related to the lead.');
        System.assertEquals('Follow-up', result[0].Subject, 'Task subject should be Follow-up.');
        System.assertEquals('Not Started', result[0].Status, 'Task status should be Not Started.');
    }

    @isTest
    static void testBulkOperations() {
        List<Lead> leads = [SELECT Id FROM Lead];
        List<Id> leadIds = new List<Id>();
        for (Lead l : leads) {
            leadIds.add(l.Id);
        }

        Test.startTest();
        List<Lead> assigned = LeadFollowUpController.assignLeadToCurrentUser(leadIds);
        List<Lead> updated = LeadFollowUpController.updateLeadStatus(leadIds, 'Working - Contacted');
        List<Task> tasks = LeadFollowUpController.createFollowUpTask(leadIds);
        Test.stopTest();

        System.assertEquals(210, assigned.size(), 'All leads should be assigned.');
        System.assertEquals(210, updated.size(), 'All leads should have updated status.');
        System.assertEquals(210, tasks.size(), 'A task should be created for every lead.');

        for (Lead l : assigned) {
            System.assertEquals(UserInfo.getUserId(), l.OwnerId, 'Every lead owner should be the current user.');
        }
    }

    @isTest
    static void testAssignLeadNullListErrors() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            LeadFollowUpController.assignLeadToCurrentUser(null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('required'), 'Exception message should indicate a Lead Id is required.');
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'An exception should be thrown when lead ids are null.');
    }

    @isTest
    static void testUpdateLeadStatusBlankErrors() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            LeadFollowUpController.updateLeadStatus(new List<Id>{ testLead.Id }, '');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'An exception should be thrown when status is blank.');
    }

    @isTest
    static void testCreateFollowUpTaskEmptyListErrors() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            LeadFollowUpController.createFollowUpTask(new List<Id>());
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'An exception should be thrown when lead ids are empty.');
    }
}