public with sharing class LeadFollowUpController {

    @AuraEnabled
    public static List<Lead> assignLeadToCurrentUser(List<Id> leadIds) {
        if (leadIds == null || leadIds.isEmpty()) {
            throw new AuraHandledException('At least one Lead Id is required.');
        }

        List<Lead> leads = [
            SELECT Id, OwnerId
            FROM Lead
            WHERE Id IN :leadIds
            WITH SECURITY_ENFORCED
        ];

        for (Lead l : leads) {
            l.OwnerId = UserInfo.getUserId();
        }

        try {
            update leads;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to assign lead: ' + e.getMessage());
        }

        return leads;
    }

    @AuraEnabled
    public static List<Lead> updateLeadStatus(List<Id> leadIds, String newStatus) {
        if (leadIds == null || leadIds.isEmpty()) {
            throw new AuraHandledException('At least one Lead Id is required.');
        }
        if (String.isBlank(newStatus)) {
            throw new AuraHandledException('Lead Status is required.');
        }

        List<Lead> leads = [
            SELECT Id, Status
            FROM Lead
            WHERE Id IN :leadIds
            WITH SECURITY_ENFORCED
        ];

        for (Lead l : leads) {
            l.Status = newStatus;
        }

        try {
            update leads;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to update lead status: ' + e.getMessage());
        }

        return leads;
    }

    @AuraEnabled
    public static List<Task> createFollowUpTask(List<Id> leadIds) {
        if (leadIds == null || leadIds.isEmpty()) {
            throw new AuraHandledException('At least one Lead Id is required.');
        }

        List<Task> tasks = new List<Task>();
        for (Id leadId : leadIds) {
            tasks.add(new Task(
                WhoId = leadId,
                Subject = 'Follow-up',
                Status = 'Not Started',
                Priority = 'Normal',
                ActivityDate = Date.today().addDays(3)
            ));
        }

        try {
            insert tasks;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to create follow-up task: ' + e.getMessage());
        }

        return tasks;
    }
}