public with sharing class LeadAssignmentFollowUpController {

    @AuraEnabled
    public static Integer assignLeadToCurrentUser(List<Id> leadIds) {
        if (leadIds == null || leadIds.isEmpty()) {
            return 0;
        }

        List<Id> validIds = new List<Id>();
        for (Id leadId : leadIds) {
            if (leadId != null) {
                validIds.add(leadId);
            }
        }
        if (validIds.isEmpty()) {
            return 0;
        }

        if (!Lead.SObjectType.getDescribe().isUpdateable()) {
            throw new AuraHandledException('Insufficient permissions to update Leads.');
        }
        if (!Lead.OwnerId.getDescribe().isUpdateable()) {
            throw new AuraHandledException('Insufficient permissions to update the Lead Owner.');
        }

        List<Lead> leadsToUpdate = [
            SELECT Id, OwnerId
            FROM Lead
            WHERE Id IN :validIds
            WITH SECURITY_ENFORCED
            LIMIT 50000
        ];

        Id currentUserId = UserInfo.getUserId();
        for (Lead l : leadsToUpdate) {
            l.OwnerId = currentUserId;
        }

        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPDATABLE, leadsToUpdate);
        update decision.getRecords();
        return decision.getRecords().size();
    }

    @AuraEnabled
    public static Integer createFollowUpTask(List<Id> leadIds, String subject, Date activityDate) {
        if (leadIds == null || leadIds.isEmpty()) {
            return 0;
        }
        if (String.isBlank(subject)) {
            throw new AuraHandledException('Task subject is required.');
        }

        if (!Task.SObjectType.getDescribe().isCreateable()) {
            throw new AuraHandledException('Insufficient permissions to create Tasks.');
        }
        if (!Task.WhatId.getDescribe().isCreateable()
            || !Task.Subject.getDescribe().isCreateable()
            || !Task.ActivityDate.getDescribe().isCreateable()
            || !Task.Status.getDescribe().isCreateable()
            || !Task.Priority.getDescribe().isCreateable()) {
            throw new AuraHandledException('Insufficient field permissions to create a Task.');
        }

        List<Id> validIds = new List<Id>();
        for (Id leadId : leadIds) {
            if (leadId != null) {
                validIds.add(leadId);
            }
        }
        if (validIds.isEmpty()) {
            return 0;
        }

        List<Lead> leads = [
            SELECT Id
            FROM Lead
            WHERE Id IN :validIds
            WITH SECURITY_ENFORCED
            LIMIT 50000
        ];

        List<Task> tasksToInsert = new List<Task>();
        for (Lead l : leads) {
            tasksToInsert.add(new Task(
                WhatId = l.Id,
                Subject = subject,
                ActivityDate = activityDate,
                Status = 'Not Started',
                Priority = 'Normal'
            ));
        }

        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, tasksToInsert);
        insert decision.getRecords();
        return decision.getRecords().size();
    }
}