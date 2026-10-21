public with sharing class CaseActivityController {
    private static final Integer DEFAULT_ROW_LIMIT = 10;
    private static final Integer MAX_ROW_LIMIT = 1000;

    @AuraEnabled(cacheable=true)
    public static List<Task> getRecentCaseActivities(Id caseId, Integer rowLimit) {
        if (caseId == null) {
            throw new AuraHandledException('caseId cannot be null.');
        }

        Integer effectiveLimit = (rowLimit == null || rowLimit <= 0)
            ? DEFAULT_ROW_LIMIT
            : Math.min(rowLimit, MAX_ROW_LIMIT);

        List<Task> activities = [
            SELECT Id, Subject, ActivityDate, Owner.Name, Status, WhatId
            FROM Task
            WHERE WhatId = :caseId
            WITH SECURITY_ENFORCED
            ORDER BY ActivityDate DESC NULLS LAST, CreatedDate DESC
            LIMIT :effectiveLimit
        ];

        if (!activities.isEmpty()) {
            activities = Security.stripInaccessible(AccessType.READABLE, activities).getRecords();
        }

        return activities;
    }
}