@isTest
public with sharing class CaseTriggerHandlerTest {

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
    static void onBeforeInsert_RoutesToQueue() {
        Case c = new Case(
            Subject = 'Handler Insert',
            Status = 'New',
            Origin = 'Email',
            Product_Category__c = 'Hardware',
            Customer_Region__c = 'North America',
            Priority = 'High'
        );

        Test.startTest();
        CaseTriggerHandler.onBeforeInsert(new List<Case>{c});
        Test.stopTest();

        Id expectedQueue = getQueueId('NA_Hardware_High');
        System.assertEquals(expectedQueue, c.OwnerId, 'Handler should route case on before insert');
    }

    @isTest
    static void onBeforeUpdate_RoutesWhenChanged() {
        Case c = new Case(
            Subject = 'Handler Update',
            Status = 'New',
            Origin = 'Email',
            Product_Category__c = 'Other',
            Customer_Region__c = 'Other',
            Priority = 'Low'
        );
        insert c;

        Map<Id, Case> oldMap = new Map<Id, Case>([
            SELECT Id, Product_Category__c, Customer_Region__c, Priority
            FROM Case
            WHERE Id = :c.Id
            WITH SECURITY_ENFORCED
        ]);

        c.Product_Category__c = 'Hardware';
        c.Customer_Region__c = 'North America';
        c.Priority = 'High';

        Test.startTest();
        CaseTriggerHandler.onBeforeUpdate(new List<Case>{c}, oldMap);
        Test.stopTest();

        Id expectedQueue = getQueueId('NA_Hardware_High');
        System.assertEquals(expectedQueue, c.OwnerId, 'Handler should route case on before update when routing fields change');
    }
}