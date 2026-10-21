@isTest
public with sharing class LeadAssignmentFollowUpControllerTest {

    @TestSetup
    static void setupData() {
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 210; i++) {
            leads.add(new Lead(LastName = 'TestLead' + i, Company = 'TestCo'));
        }
        Test.startTest();
        insert leads;
        Test.stopTest();
    }

    @isTest
    static void testAssignLeadToCurrentUser() {
        List<Lead> leads = [SELECT Id FROM Lead LIMIT 5];
        List<Id> leadIds = new List<Id>();
        for (Lead l : leads) {
            leadIds.add(l.Id);
        }

        Test.startTest();
        Integer assignedCount = LeadAssignmentFollowUpController.assignLeadToCurrentUser(leadIds);
        Test.stopTest();

        System.assertEquals(leadIds.size(), assignedCount, 'All selected leads should be assigned.');
        for (Lead l : [SELECT OwnerId FROM Lead WHERE Id IN :leadIds]) {
            System.assertEquals(UserInfo.getUserId(), l.OwnerId, 'Lead owner should be the current user.');
        }
    }

    @isTest
    static void testAssignLeadToCurrentUserBulk() {
        List<Lead> leads = [SELECT Id FROM Lead];
        List<Id> leadIds = new List<Id>();
        for (Lead l : leads) {
            leadIds.add(l.Id);
        }

        Test.startTest();
        Integer assignedCount = LeadAssignmentFollowUpController.assignLeadToCurrentUser(leadIds);
        Test.stopTest();

        System.assertEquals(leadIds.size(), assignedCount, 'All bulk leads should be assigned.');
        System.assertEquals(210, [SELECT COUNT() FROM Lead WHERE OwnerId = :UserInfo.getUserId()], 'All bulk leads should be owned by the current user.');
    }

    @isTest
    static void testCreateFollowUpTask() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        Date dueDate = Date.today().addDays(2);

        Test.startTest();
        Integer createdCount = LeadAssignmentFollowUpController.createFollowUpTask(new List<Id>{ testLead.Id }, 'Follow up', dueDate);
        Test.stopTest();

        System.assertEquals(1, createdCount, 'One task should be created.');
        List<Task> tasks = [SELECT WhatId, Subject, ActivityDate, Status, Priority FROM Task WHERE WhatId = :testLead.Id];
        System.assertEquals(1, tasks.size(), 'Exactly one task should exist for the lead.');
        System.assertEquals('Follow up', tasks[0].Subject, 'Task subject should match.');
        System.assertEquals(dueDate, tasks[0].ActivityDate, 'Task due date should match.');
        System.assertEquals('Not Started', tasks[0].Status, 'Task status should default to Not Started.');
        System.assertEquals('Normal', tasks[0].Priority, 'Task priority should default to Normal.');
    }

    @isTest
    static void testCreateFollowUpTaskBulk() {
        List<Lead> leads = [SELECT Id FROM Lead];
        List<Id> leadIds = new List<Id>();
        for (Lead l : leads) {
            leadIds.add(l.Id);
        }
        Date dueDate = Date.today().addDays(3);

        Test.startTest();
        Integer createdCount = LeadAssignmentFollowUpController.createFollowUpTask(leadIds, 'Bulk follow up', dueDate);
        Test.stopTest();

        System.assertEquals(leadIds.size(), createdCount, 'All bulk tasks should be created.');
        System.assertEquals(210, [SELECT COUNT() FROM Task WHERE Subject = 'Bulk follow up'], 'All bulk follow-up tasks should exist.');
    }

    @isTest
    static void testEmptyInputsReturnZero() {
        System.assertEquals(0, LeadAssignmentFollowUpController.assignLeadToCurrentUser(new List<Id>()), 'Empty lead list should return zero assignments.');
        System.assertEquals(0, LeadAssignmentFollowUpController.createFollowUpTask(new List<Id>(), 'Subject', Date.today()), 'Empty lead list should return zero tasks.');
    }
}