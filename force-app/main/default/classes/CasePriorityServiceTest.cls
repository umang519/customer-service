@isTest
public with sharing class CasePriorityServiceTest {

    @TestSetup
    static void setupTestData() {
        Case testCase = new Case(
            Subject = 'Test Priority Case',
            Status = 'New',
            Origin = 'Email'
        );
        insert testCase;
    }

    @isTest
    static void testUpdateCasePrioritySuccess() {
        Case testCase = [SELECT Id, Priority FROM Case LIMIT 1];

        Test.startTest();
        Case result = CasePriorityService.updateCasePriority(testCase.Id, 'High');
        Test.stopTest();

        System.assertEquals('High', result.Priority, 'Returned Case priority should be High');

        Case updatedCase = [SELECT Id, Priority FROM Case WHERE Id = :testCase.Id];
        System.assertEquals('High', updatedCase.Priority, 'Stored Case priority should be High');
    }

    @isTest
    static void testUpdateCasePriorityInvalidIdType() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Boolean exceptionThrown = false;
        String errorMessage = '';

        Test.startTest();
        try {
            CasePriorityService.updateCasePriority(testAccount.Id, 'High');
        } catch (Exception e) {
            exceptionThrown = true;
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Expected an exception for a non-Case ID');
        System.assert(errorMessage.contains('not a Case ID'), 'Expected not a Case ID error but got: ' + errorMessage);
    }

    @isTest
    static void testUpdateCasePriorityNonExistentCase() {
        String caseKeyPrefix = Case.SObjectType.getDescribe().getKeyPrefix();
        Id nonExistentCaseId = (Id)(caseKeyPrefix + '000000000001');

        Boolean exceptionThrown = false;
        String errorMessage = '';

        Test.startTest();
        try {
            CasePriorityService.updateCasePriority(nonExistentCaseId, 'High');
        } catch (Exception e) {
            exceptionThrown = true;
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Expected an exception for a non-existent Case');
        System.assert(errorMessage.contains('not found'), 'Expected record not found error but got: ' + errorMessage);
    }

    @isTest
    static void testUpdateCasePriorityBlankPriority() {
        Case testCase = [SELECT Id, Priority FROM Case LIMIT 1];

        Boolean exceptionThrown = false;
        String errorMessage = '';

        Test.startTest();
        try {
            CasePriorityService.updateCasePriority(testCase.Id, '  ');
        } catch (Exception e) {
            exceptionThrown = true;
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Expected an exception for blank priority');
        System.assert(errorMessage.contains('blank'), 'Expected blank priority error but got: ' + errorMessage);
    }

    @isTest
    static void testUpdateCasePriorityInvalidPriority() {
        Case testCase = [SELECT Id, Priority FROM Case LIMIT 1];

        Boolean exceptionThrown = false;
        String errorMessage = '';

        Test.startTest();
        try {
            CasePriorityService.updateCasePriority(testCase.Id, 'Critical');
        } catch (Exception e) {
            exceptionThrown = true;
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Expected an exception for unsupported priority');
        System.assert(errorMessage.contains('Unsupported priority'), 'Expected unsupported priority error but got: ' + errorMessage);
    }

    @isTest
    static void testUpdateCasePriorityBulk() {
        List<Case> casesToInsert = new List<Case>();
        for (Integer i = 0; i < 200; i++) {
            casesToInsert.add(new Case(
                Subject = 'Bulk Test Case ' + i,
                Status = 'New',
                Origin = 'Email'
            ));
        }
        insert casesToInsert;

        List<Id> caseIds = new List<Id>();
        for (Case c : casesToInsert) {
            caseIds.add(c.Id);
        }

        Test.startTest();
        List<Case> results = CasePriorityService.updateCasePriority(caseIds, 'High');
        Test.stopTest();

        System.assertEquals(200, results.size(), 'Bulk update should return 200 Cases');

        Integer highPriorityCount = [SELECT COUNT() FROM Case WHERE Id IN :caseIds AND Priority = 'High'];
        System.assertEquals(200, highPriorityCount, 'All 200 Cases should have Priority High');
    }
}