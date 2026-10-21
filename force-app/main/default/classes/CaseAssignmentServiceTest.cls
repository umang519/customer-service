@isTest
public with sharing class CaseAssignmentServiceTest {

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
    static void assignCases_Insert_SpecificRule() {
        Case c = new Case(
            Subject = 'Test Specific Rule',
            Status = 'New',
            Origin = 'Email',
            Product_Category__c = 'Hardware',
            Customer_Region__c = 'North America',
            Priority = 'High'
        );

        Test.startTest();
        CaseAssignmentService.assignCases(new List<Case>{c}, null);
        Test.stopTest();

        Id expectedQueue = getQueueId('NA_Hardware_High');
        System.assertEquals(expectedQueue, c.OwnerId, 'Case should be routed to the specific queue');
    }

    @isTest
    static void assignCases_Insert_DefaultRule() {
        Case c = new Case(
            Subject = 'Test Default Rule',
            Status = 'New',
            Origin = 'Email',
            Product_Category__c = 'Other',
            Customer_Region__c = 'Other',
            Priority = 'Low'
        );

        Test.startTest();
        CaseAssignmentService.assignCases(new List<Case>{c}, null);
        Test.stopTest();

        Id expectedQueue = getQueueId('Default_Support_Queue');
        System.assertEquals(expectedQueue, c.OwnerId, 'Case should fall back to the default queue');
    }

    @isTest
    static void assignCases_BulkInsert() {
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < 200; i++) {
            cases.add(new Case(
                Subject = 'Bulk ' + i,
                Status = 'New',
                Origin = 'Email',
                Product_Category__c = Math.mod(i, 2) == 0 ? 'Hardware' : 'Software',
                Customer_Region__c = Math.mod(i, 2) == 0 ? 'North America' : 'Europe',
                Priority = Math.mod(i, 2) == 0 ? 'High' : 'Medium'
            ));
        }

        Test.startTest();
        insert cases;
        Test.stopTest();

        Map<Id, Case> caseMap = new Map<Id, Case>([
            SELECT Id, OwnerId
            FROM Case
            WHERE Id IN :cases
            WITH SECURITY_ENFORCED
        ]);

        Id hardwareQueue = getQueueId('NA_Hardware_High');
        Id softwareQueue = getQueueId('EU_Software_Medium');
        Integer hardwareCount = 0;
        Integer softwareCount = 0;

        for (Case c : cases) {
            Case inserted = caseMap.get(c.Id);
            System.assert(inserted.OwnerId != null, 'Owner should be set by assignment service');
            if (inserted.OwnerId == hardwareQueue) {
                hardwareCount++;
            }
            if (inserted.OwnerId == softwareQueue) {
                softwareCount++;
            }
        }

        System.assert(hardwareCount > 0, 'Bulk insert should assign cases to the hardware queue');
        System.assert(softwareCount > 0, 'Bulk insert should assign cases to the software queue');
    }

    @isTest
    static void assignCases_Update_NoRelevantChange() {
        Case c = new Case(
            Subject = 'No Relevant Change',
            Status = 'New',
            Origin = 'Email',
            Product_Category__c = 'Hardware',
            Customer_Region__c = 'North America',
            Priority = 'High'
        );
        insert c;

        c = [SELECT OwnerId FROM Case WHERE Id = :c.Id WITH SECURITY_ENFORCED];
        Id originalOwner = c.OwnerId;

        c.Subject = 'Changed Subject Only';
        Test.startTest();
        update c;
        Test.stopTest();

        c = [SELECT OwnerId FROM Case WHERE Id = :c.Id WITH SECURITY_ENFORCED];
        System.assertEquals(originalOwner, c.OwnerId, 'Owner should remain unchanged when routing fields do not change');
    }

    @isTest
    static void assignCases_Update_RelevantChange() {
        Case c = new Case(
            Subject = 'Relevant Change',
            Status = 'New',
            Origin = 'Email',
            Product_Category__c = 'Other',
            Customer_Region__c = 'Other',
            Priority = 'Low'
        );
        insert c;

        Id defaultQueue = [SELECT OwnerId FROM Case WHERE Id = :c.Id WITH SECURITY_ENFORCED].OwnerId;

        c.Product_Category__c = 'Hardware';
        c.Customer_Region__c = 'North America';
        c.Priority = 'High';

        Test.startTest();
        update c;
        Test.stopTest();

        Id hardwareQueue = getQueueId('NA_Hardware_High');
        c = [SELECT OwnerId FROM Case WHERE Id = :c.Id WITH SECURITY_ENFORCED];
        System.assertEquals(hardwareQueue, c.OwnerId, 'Owner should be reassigned when routing fields change');
        System.assert(defaultQueue != c.OwnerId, 'Owner should no longer be the default queue');
    }
}