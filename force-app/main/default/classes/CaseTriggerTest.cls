@isTest
public with sharing class CaseTriggerTest {

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
    static void triggerBeforeInsert_AssignsQueue() {
        Case c = new Case(
            Subject = 'Trigger Insert',
            Status = 'New',
            Origin = 'Email',
            Product_Category__c = 'Hardware',
            Customer_Region__c = 'North America',
            Priority = 'High'
        );

        Test.startTest();
        insert c;
        Test.stopTest();

        c = [SELECT OwnerId FROM Case WHERE Id = :c.Id WITH SECURITY_ENFORCED];
        Id expectedQueue = getQueueId('NA_Hardware_High');
        System.assertEquals(expectedQueue, c.OwnerId, 'Trigger should assign case to queue on insert');
    }

    @isTest
    static void triggerBeforeUpdate_ReassignsWhenChanged() {
        Case c = new Case(
            Subject = 'Trigger Update',
            Status = 'New',
            Origin = 'Email',
            Product_Category__c = 'Other',
            Customer_Region__c = 'Other',
            Priority = 'Low'
        );
        insert c;

        c.Product_Category__c = 'Hardware';
        c.Customer_Region__c = 'North America';
        c.Priority = 'High';

        Test.startTest();
        update c;
        Test.stopTest();

        c = [SELECT OwnerId FROM Case WHERE Id = :c.Id WITH SECURITY_ENFORCED];
        Id expectedQueue = getQueueId('NA_Hardware_High');
        System.assertEquals(expectedQueue, c.OwnerId, 'Trigger should reassign case when routing fields change');
    }
}