@isTest
private class CaseActivityControllerTest {
    private static final Integer BULK_COUNT = 250;

    @TestSetup
    static void setupTestData() {
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Email'
        );
        insert testCase;

        List<Task> tasks = new List<Task>();
        for (Integer i = 0; i < BULK_COUNT; i++) {
            tasks.add(new Task(
                Subject = 'Activity ' + i,
                WhatId = testCase.Id,
                Status = 'Not Started',
                Priority = 'Normal',
                ActivityDate = Date.today().addDays(-i)
            ));
        }
        insert tasks;
    }

    @isTest
    static void testGetRecentCaseActivities_Positive() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();
        List<Task> result = CaseActivityController.getRecentCaseActivities(testCase.Id, 5);
        Test.stopTest();

        System.assertEquals(5, result.size(), 'Expected 5 activities to be returned');
        System.assertEquals('Activity 0', result[0].Subject, 'Most recent activity should be returned first');

        for (Task t : result) {
            System.assertEquals(testCase.Id, t.WhatId, 'Each activity must be related to the case');
            System.assert(!String.isBlank(t.Owner.Name), 'Owner name should be populated');
        }
    }

    @isTest
    static void testGetRecentCaseActivities_NullCaseId() {
        Test.startTest();
        try {
            CaseActivityController.getRecentCaseActivities(null, 5);
            System.assert(false, 'Expected AuraHandledException for null caseId');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('caseId'), 'Exception message should reference caseId');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetRecentCaseActivities_NullRowLimit() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();
        List<Task> result = CaseActivityController.getRecentCaseActivities(testCase.Id, null);
        Test.stopTest();

        System.assertEquals(10, result.size(), 'Null row limit should default to 10');
    }

    @isTest
    static void testGetRecentCaseActivities_NegativeRowLimit() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();
        List<Task> result = CaseActivityController.getRecentCaseActivities(testCase.Id, -5);
        Test.stopTest();

        System.assertEquals(10, result.size(), 'Negative row limit should default to 10');
    }

    @isTest
    static void testGetRecentCaseActivities_InvalidCaseId() {
        Id invalidId = '500000000000000000';

        Test.startTest();
        List<Task> result = CaseActivityController.getRecentCaseActivities(invalidId, 10);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Invalid caseId should return an empty list');
    }

    @isTest
    static void testGetRecentCaseActivities_Bulk() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();
        List<Task> result = CaseActivityController.getRecentCaseActivities(testCase.Id, BULK_COUNT);
        Test.stopTest();

        System.assertEquals(BULK_COUNT, result.size(), 'Expected all bulk activities to be returned');
    }
}