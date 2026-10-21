public with sharing class CasePriorityService {

    public static Case updateCasePriority(Id caseId, String newPriority) {
        validateCaseId(caseId);
        validatePriority(newPriority);

        List<Case> cases = [
            SELECT Id, Priority
            FROM Case
            WHERE Id = :caseId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        if (cases.isEmpty()) {
            throw new AuraHandledException('Case record not found for the provided ID.');
        }

        Case currentCase = cases[0];
        currentCase.Priority = newPriority;

        update currentCase;

        return [
            SELECT Id, Priority
            FROM Case
            WHERE Id = :caseId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
    }

    public static List<Case> updateCasePriority(List<Id> caseIds, String newPriority) {
        if (caseIds == null || caseIds.isEmpty()) {
            throw new AuraHandledException('Case IDs cannot be null or empty.');
        }

        for (Id caseId : caseIds) {
            validateCaseId(caseId);
        }

        validatePriority(newPriority);

        Set<Id> uniqueCaseIds = new Set<Id>(caseIds);

        List<Case> cases = [
            SELECT Id, Priority
            FROM Case
            WHERE Id IN :uniqueCaseIds
            WITH SECURITY_ENFORCED
        ];

        if (cases.size() != uniqueCaseIds.size()) {
            throw new AuraHandledException('One or more Case records were not found.');
        }

        for (Case currentCase : cases) {
            currentCase.Priority = newPriority;
        }

        update cases;

        return [
            SELECT Id, Priority
            FROM Case
            WHERE Id IN :uniqueCaseIds
            WITH SECURITY_ENFORCED
        ];
    }

    private static void validateCaseId(Id caseId) {
        if (caseId == null) {
            throw new AuraHandledException('Case ID cannot be null.');
        }
        if (caseId.getSObjectType() != Case.SObjectType) {
            throw new AuraHandledException('The provided ID is not a Case ID.');
        }
    }

    private static void validatePriority(String newPriority) {
        if (String.isBlank(newPriority)) {
            throw new AuraHandledException('Priority value cannot be blank.');
        }

        for (Schema.PicklistEntry entry : Schema.SObjectType.Case.fields.Priority.getPicklistValues()) {
            if (entry.isActive() && entry.getValue().equalsIgnoreCase(newPriority)) {
                return;
            }
        }

        throw new AuraHandledException('Unsupported priority value: ' + newPriority);
    }
}