public with sharing class CaseAssignmentService {

    @InvocableMethod(label='Assign Cases' description='Routes cases to the appropriate queue based on product category, customer region, and priority.')
    public static void assignCasesById(List<Id> caseIds) {
        if (caseIds == null || caseIds.isEmpty()) {
            return;
        }

        List<Case> cases = [
            SELECT Id, OwnerId, Product_Category__c, Customer_Region__c, Priority
            FROM Case
            WHERE Id IN :caseIds
            WITH SECURITY_ENFORCED
        ];

        assignCases(cases, null);
    }

    public static void assignCases(List<Case> cases) {
        assignCases(cases, null);
    }

    public static void assignCases(List<Case> cases, Map<Id, Case> oldMap) {
        if (cases == null || cases.isEmpty()) {
            return;
        }

        List<Case> casesToRoute = new List<Case>();
        for (Case c : cases) {
            if (oldMap == null || hasRelevantChange(c, oldMap.get(c.Id))) {
                casesToRoute.add(c);
            }
        }

        if (casesToRoute.isEmpty()) {
            return;
        }

        List<Case_Assignment_Rule__mdt> rules = [
            SELECT Product_Category__c, Customer_Region__c, Priority__c, Target_Queue_Developer_Name__c
            FROM Case_Assignment_Rule__mdt
            WHERE Is_Active__c = TRUE
            WITH SECURITY_ENFORCED
        ];

        Set<String> targetQueueNames = new Set<String>();
        Map<String, Case_Assignment_Rule__mdt> exactRules = new Map<String, Case_Assignment_Rule__mdt>();
        Case_Assignment_Rule__mdt defaultRule;

        for (Case_Assignment_Rule__mdt rule : rules) {
            if (String.isNotBlank(rule.Target_Queue_Developer_Name__c)) {
                targetQueueNames.add(rule.Target_Queue_Developer_Name__c);
            }

            Boolean isDefault = String.isBlank(rule.Product_Category__c)
                             && String.isBlank(rule.Customer_Region__c)
                             && String.isBlank(rule.Priority__c);

            if (isDefault) {
                defaultRule = rule;
            } else {
                exactRules.put(buildKey(rule.Product_Category__c, rule.Customer_Region__c, rule.Priority__c), rule);
            }
        }

        Map<String, Id> queueIdByName = new Map<String, Id>();
        if (!targetQueueNames.isEmpty()) {
            for (Group q : [
                SELECT Id, DeveloperName
                FROM Group
                WHERE Type = 'Queue'
                  AND DeveloperName IN :targetQueueNames
                WITH SECURITY_ENFORCED
            ]) {
                queueIdByName.put(q.DeveloperName, q.Id);
            }
        }

        for (Case c : casesToRoute) {
            Case_Assignment_Rule__mdt matched = exactRules.get(buildKey(c.Product_Category__c, c.Customer_Region__c, c.Priority));
            if (matched == null) {
                matched = defaultRule;
            }

            if (matched == null || String.isBlank(matched.Target_Queue_Developer_Name__c)) {
                continue;
            }

            Id queueId = queueIdByName.get(matched.Target_Queue_Developer_Name__c);
            if (queueId == null) {
                continue;
            }

            c.OwnerId = queueId;
        }
    }

    private static Boolean hasRelevantChange(Case newCase, Case oldCase) {
        if (oldCase == null) {
            return true;
        }
        return newCase.Product_Category__c != oldCase.Product_Category__c
            || newCase.Customer_Region__c != oldCase.Customer_Region__c
            || newCase.Priority != oldCase.Priority;
    }

    private static String buildKey(String category, String region, String priority) {
        return String.join(new List<String>{
            category == null ? '' : category,
            region == null ? '' : region,
            priority == null ? '' : priority
        }, '|');
    }
}