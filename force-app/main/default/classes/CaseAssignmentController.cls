public with sharing class CaseAssignmentController {

    @AuraEnabled(cacheable=true)
    public static OwnerOption getCurrentOwner(Id caseId) {
        if (caseId == null) {
            return null;
        }

        List<Case> cases = [
            SELECT Id, OwnerId, Owner.Name
            FROM Case
            WHERE Id = :caseId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        if (cases.isEmpty()) {
            return null;
        }

        Case c = cases[0];
        String ownerType = (c.OwnerId.getSobjectType() == User.SObjectType) ? 'User' : 'Queue';
        return new OwnerOption(c.OwnerId, (String)c.Owner.Name, ownerType);
    }

    @AuraEnabled(cacheable=true)
    public static List<OwnerOption> searchOwners(String searchTerm) {
        List<OwnerOption> options = new List<OwnerOption>();

        if (String.isBlank(searchTerm)) {
            return options;
        }

        String likeTerm = '%' + searchTerm + '%';

        for (User u : [
            SELECT Id, Name
            FROM User
            WHERE IsActive = TRUE
              AND Name LIKE :likeTerm
            WITH SECURITY_ENFORCED
            ORDER BY Name
            LIMIT 25
        ]) {
            options.add(new OwnerOption(u.Id, u.Name, 'User'));
        }

        for (Group q : [
            SELECT Id, Name
            FROM Group
            WHERE Type = 'Queue'
              AND Name LIKE :likeTerm
            WITH SECURITY_ENFORCED
            ORDER BY Name
            LIMIT 25
        ]) {
            options.add(new OwnerOption(q.Id, q.Name, 'Queue'));
        }

        return options;
    }

    @AuraEnabled
    public static void reassignCase(Id caseId, Id newOwnerId) {
        if (caseId == null || newOwnerId == null) {
            throw new AuraHandledException('Case ID and new owner are required.');
        }

        List<Case> cases = [
            SELECT Id, OwnerId
            FROM Case
            WHERE Id = :caseId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        if (cases.isEmpty()) {
            throw new AuraHandledException('Case not found.');
        }

        SObjectType ownerType = newOwnerId.getSobjectType();

        if (ownerType == User.SObjectType) {
            List<User> users = [
                SELECT Id, IsActive
                FROM User
                WHERE Id = :newOwnerId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            if (users.isEmpty() || !users[0].IsActive) {
                throw new AuraHandledException('Target user is inactive or not found.');
            }

            List<UserRecordAccess> access = [
                SELECT RecordId, HasEditAccess
                FROM UserRecordAccess
                WHERE UserId = :newOwnerId
                  AND RecordId = :caseId
                LIMIT 1
            ];

            if (access.isEmpty() || !access[0].HasEditAccess) {
                throw new AuraHandledException('Target user does not have edit access to this case.');
            }
        } else if (ownerType == Group.SObjectType) {
            List<Group> queues = [
                SELECT Id
                FROM Group
                WHERE Id = :newOwnerId
                  AND Type = 'Queue'
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            if (queues.isEmpty()) {
                throw new AuraHandledException('Target queue not found.');
            }

            List<QueueSobject> supportedObjects = [
                SELECT Id
                FROM QueueSobject
                WHERE QueueId = :newOwnerId
                  AND SobjectType = 'Case'
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            if (supportedObjects.isEmpty()) {
                throw new AuraHandledException('Target queue does not support Case objects.');
            }
        } else {
            throw new AuraHandledException('Invalid owner type.');
        }

        Case c = cases[0];
        c.OwnerId = newOwnerId;
        update c;
    }

    public class OwnerOption {
        @AuraEnabled public Id value;
        @AuraEnabled public String label;
        @AuraEnabled public String type;

        public OwnerOption(Id value, String label, String type) {
            this.value = value;
            this.label = label;
            this.type = type;
        }
    }
}