@isTest
public with sharing class CaseAssignmentControllerTest {

    @TestSetup
    static void setup() {
        Case c = new Case(
            Subject = 'Controller Test Case',
            Status = 'New',
            Origin = 'Email',
            Product_Category__c = 'Hardware',
            Customer_Region__c = 'North America',
            Priority = 'High'
        );
        insert c;
    }

    private static Case getTestCase() {
        return [SELECT Id, OwnerId FROM Case WITH SECURITY_ENFORCED LIMIT 1];
    }

    private static Id getQueueId(String developerName) {
        List<Group> groups = [
            SELECT Id
            FROM Group
            WHERE Type = 'Queue'
              AND DeveloperName = :developerName
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        System.assert(!groups.isEmpty(), 'Queue ' + developerName + ' must exist for test data');
        return groups[0].Id;
    }

    @isTest
    static void getCurrentOwner_ReturnsOwner() {
        Case c = getTestCase();

        Test.startTest();
        CaseAssignmentController.OwnerOption owner = CaseAssignmentController.getCurrentOwner(c.Id);
        Test.stopTest();

        System.assert(owner != null, 'An owner option should be returned');
        System.assertEquals(c.OwnerId, owner.value, 'Owner option value should match the case owner');
    }

    @isTest
    static void searchOwners_ReturnsUserAndQueue() {
        String userTerm = UserInfo.getName().substring(0, Math.min(3, UserInfo.getName().length()));

        Test.startTest();
        List<CaseAssignmentController.OwnerOption> results = CaseAssignmentController.searchOwners(userTerm);
        List<CaseAssignmentController.OwnerOption> queueResults = CaseAssignmentController.searchOwners('Hardware');
        Test.stopTest();

        System.assert(results != null && !results.isEmpty(), 'User search should return results');
        Boolean foundUser = false;
        for (CaseAssignmentController.OwnerOption opt : results) {
            if ('User'.equalsIgnoreCase(opt.type)) {
                foundUser = true;
                break;
            }
        }
        System.assert(foundUser, 'Search should return at least one user');

        System.assert(queueResults != null && !queueResults.isEmpty(), 'Queue search should return results');
        Boolean foundQueue = false;
        for (CaseAssignmentController.OwnerOption opt : queueResults) {
            if ('Queue'.equalsIgnoreCase(opt.type)) {
                foundQueue = true;
                break;
            }
        }
        System.assert(foundQueue, 'Search should return at least one queue');
    }

    @isTest
    static void reassignCase_ToActiveUser_Succeeds() {
        Case c = getTestCase();
        Id userId = UserInfo.getUserId();

        Test.startTest();
        CaseAssignmentController.reassignCase(c.Id, userId);
        Test.stopTest();

        c = [SELECT OwnerId FROM Case WHERE Id = :c.Id WITH SECURITY_ENFORCED];
        System.assertEquals(userId, c.OwnerId, 'Case owner should be the active user');
    }

    @isTest
    static void reassignCase_ToQueue_Succeeds() {
        Case c = getTestCase();
        Id queueId = getQueueId('NA_Hardware_High');

        Test.startTest();
        CaseAssignmentController.reassignCase(c.Id, queueId);
        Test.stopTest();

        c = [SELECT OwnerId FROM Case WHERE Id = :c.Id WITH SECURITY_ENFORCED];
        System.assertEquals(queueId, c.OwnerId, 'Case owner should be the target queue');
    }

    @isTest
    static void reassignCase_InvalidOwner_ThrowsException() {
        Case c = getTestCase();
        Group regularGroup = new Group(
            Name = 'Regular Test Group',
            DeveloperName = 'Regular_Test_Group',
            Type = 'Regular'
        );
        insert regularGroup;

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            CaseAssignmentController.reassignCase(c.Id, regularGroup.Id);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Reassignment to a non-queue group should throw an exception');
    }
}