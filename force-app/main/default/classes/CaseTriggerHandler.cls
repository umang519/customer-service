public with sharing class CaseTriggerHandler {

    public static void onBeforeInsert(List<Case> newRecords) {
        CaseAssignmentService.assignCases(newRecords, null);
    }

    public static void onBeforeUpdate(List<Case> newRecords, Map<Id, Case> oldMap) {
        CaseAssignmentService.assignCases(newRecords, oldMap);
    }
}