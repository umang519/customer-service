public with sharing class CaseWebFormController {
    private static final Integer MAX_NAME_LENGTH = 80;
    private static final Integer MAX_EMAIL_LENGTH = 80;
    private static final Integer MAX_SUBJECT_LENGTH = 255;
    private static final Integer MAX_DESCRIPTION_LENGTH = 32000;
    private static final Set<String> VALID_PRIORITIES = new Set<String>{'High', 'Medium', 'Low'};

    public class CaseRequest {
        public String customerName;
        public String customerEmail;
        public String subject;
        public String description;
        public String priority;
    }

    @AuraEnabled
    public static String createCase(String customerName, String customerEmail, String subject, String description, String priority) {
        CaseRequest request = new CaseRequest();
        request.customerName = customerName;
        request.customerEmail = customerEmail;
        request.subject = subject;
        request.description = description;
        request.priority = priority;

        List<String> caseIds = createCases(new List<CaseRequest>{request});
        return caseIds.isEmpty() ? null : caseIds[0];
    }

    @TestVisible
    private static List<String> createCases(List<CaseRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            return new List<String>();
        }

        List<Case> casesToInsert = new List<Case>();
        for (CaseRequest request : requests) {
            validateAndSanitize(request);
            casesToInsert.add(buildCase(request));
        }

        try {
            insert casesToInsert;
        } catch (DmlException ex) {
            throw new AuraHandledException('Unable to create case: ' + ex.getDmlMessage(0));
        } catch (Exception ex) {
            throw new AuraHandledException('Unable to create case: ' + ex.getMessage());
        }

        List<String> caseIds = new List<String>();
        for (Case newCase : casesToInsert) {
            caseIds.add(newCase.Id);
        }
        return caseIds;
    }

    private static void validateAndSanitize(CaseRequest request) {
        if (request == null) {
            throw new AuraHandledException('Case request is required.');
        }

        request.customerName = sanitize(request.customerName);
        request.customerEmail = sanitize(request.customerEmail);
        request.subject = sanitize(request.subject);
        request.description = sanitize(request.description);
        request.priority = sanitize(request.priority);

        if (String.isBlank(request.customerName)) {
            throw new AuraHandledException('Name is required.');
        }
        if (request.customerName.length() > MAX_NAME_LENGTH) {
            throw new AuraHandledException('Name must not exceed ' + MAX_NAME_LENGTH + ' characters.');
        }

        if (String.isBlank(request.customerEmail)) {
            throw new AuraHandledException('Email is required.');
        }
        if (!request.customerEmail.contains('@') || request.customerEmail.contains(' ')) {
            throw new AuraHandledException('Please provide a valid email address.');
        }
        if (request.customerEmail.length() > MAX_EMAIL_LENGTH) {
            throw new AuraHandledException('Email must not exceed ' + MAX_EMAIL_LENGTH + ' characters.');
        }

        if (String.isBlank(request.subject)) {
            throw new AuraHandledException('Subject is required.');
        }
        if (request.subject.length() > MAX_SUBJECT_LENGTH) {
            throw new AuraHandledException('Subject must not exceed ' + MAX_SUBJECT_LENGTH + ' characters.');
        }

        if (String.isBlank(request.description)) {
            throw new AuraHandledException('Description is required.');
        }
        if (request.description.length() > MAX_DESCRIPTION_LENGTH) {
            throw new AuraHandledException('Description must not exceed ' + MAX_DESCRIPTION_LENGTH + ' characters.');
        }

        if (String.isBlank(request.priority)) {
            throw new AuraHandledException('Priority is required.');
        }
        if (!VALID_PRIORITIES.contains(request.priority)) {
            throw new AuraHandledException('Priority must be High, Medium, or Low.');
        }
    }

    private static String sanitize(String input) {
        if (String.isBlank(input)) {
            return input;
        }
        String trimmed = input.trim();
        return trimmed.replaceAll('<[^>]*>', '');
    }

    private static Case buildCase(CaseRequest request) {
        Case newCase = new Case();
        newCase.SuppliedName = request.customerName;
        newCase.SuppliedEmail = request.customerEmail;
        newCase.Subject = request.subject;
        newCase.Description = request.description;
        newCase.Priority = request.priority;
        newCase.Origin = 'Web';
        newCase.Status = 'New';
        return newCase;
    }
}