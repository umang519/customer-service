@isTest
private class CaseWebFormControllerTest {
    @isTest
    static void testCreateCaseSuccess() {
        Test.startTest();
        String caseId = CaseWebFormController.createCase(
            'Jane Doe',
            'jane.doe@example.com',
            'Login Issue',
            'I cannot log in to my account.',
            'Medium'
        );
        Test.stopTest();

        System.assert(String.isNotBlank(caseId), 'A case ID should be returned.');

        Case createdCase = [
            SELECT Id, SuppliedName, SuppliedEmail, Subject, Description, Priority, Origin, Status
            FROM Case
            WHERE Id = :caseId
        ];

        System.assertEquals('Jane Doe', createdCase.SuppliedName, 'SuppliedName should match the submitted name.');
        System.assertEquals('jane.doe@example.com', createdCase.SuppliedEmail, 'SuppliedEmail should match the submitted email.');
        System.assertEquals('Login Issue', createdCase.Subject, 'Subject should match the submitted subject.');
        System.assertEquals('I cannot log in to my account.', createdCase.Description, 'Description should match the submitted description.');
        System.assertEquals('Medium', createdCase.Priority, 'Priority should match the submitted priority.');
        System.assertEquals('Web', createdCase.Origin, 'Origin should be Web.');
        System.assertEquals('New', createdCase.Status, 'Status should be New.');
    }

    @isTest
    static void testCreateCaseInvalidEmail() {
        Boolean exceptionThrown = false;
        try {
            CaseWebFormController.createCase('Jane Doe', 'not-an-email', 'Subject', 'Description', 'Medium');
        } catch (AuraHandledException ex) {
            exceptionThrown = true;
            System.assert(ex.getMessage().contains('valid email'), 'Expected a valid email error message.');
        }
        System.assert(exceptionThrown, 'An exception should be thrown for an invalid email address.');
    }

    @isTest
    static void testCreateCaseMissingName() {
        Boolean exceptionThrown = false;
        try {
            CaseWebFormController.createCase(null, 'jane@example.com', 'Subject', 'Description', 'Medium');
        } catch (AuraHandledException ex) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'An exception should be thrown when the customer name is missing.');
    }

    @isTest
    static void testCreateCaseInvalidPriority() {
        Boolean exceptionThrown = false;
        try {
            CaseWebFormController.createCase('Jane Doe', 'jane@example.com', 'Subject', 'Description', 'Critical');
        } catch (AuraHandledException ex) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'An exception should be thrown for an invalid priority value.');
    }

    @isTest
    static void testCreateCaseSanitizesHtml() {
        Test.startTest();
        String caseId = CaseWebFormController.createCase(
            '<b>Jane</b>',
            'jane@example.com',
            '<script>alert("xss")</script>Subject',
            '<p>Description</p>',
            'Low'
        );
        Test.stopTest();

        Case createdCase = [
            SELECT Id, SuppliedName, Subject, Description
            FROM Case
            WHERE Id = :caseId
        ];

        System.assertEquals('Jane', createdCase.SuppliedName, 'HTML tags should be removed from the customer name.');
        System.assert(!createdCase.Subject.contains('<'), 'HTML tags should be removed from the subject.');
        System.assert(!createdCase.Description.contains('<'), 'HTML tags should be removed from the description.');
    }

    @isTest
    static void testCreateCaseBulk() {
        List<CaseWebFormController.CaseRequest> requests = new List<CaseWebFormController.CaseRequest>();
        for (Integer i = 0; i < 200; i++) {
            CaseWebFormController.CaseRequest request = new CaseWebFormController.CaseRequest();
            request.customerName = 'Customer ' + i;
            request.customerEmail = 'customer' + i + '@example.com';
            request.subject = 'Subject ' + i;
            request.description = 'Description ' + i;
            request.priority = 'Low';
            requests.add(request);
        }

        Test.startTest();
        List<String> caseIds = CaseWebFormController.createCases(requests);
        Test.stopTest();

        System.assertEquals(200, caseIds.size(), 'Two hundred case IDs should be returned.');
        System.assertEquals(200, [SELECT COUNT() FROM Case], 'Two hundred cases should be created.');
    }

    @isTest
    static void testCreateCaseAsGuestUser() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
            String caseId = CaseWebFormController.createCase(
                'Guest User',
                'guest@example.com',
                'Guest Subject',
                'Guest Description',
                'Low'
            );
            Test.stopTest();

            System.assert(String.isNotBlank(caseId), 'A case should be created when invoked by a guest-class user.');
        }
    }
}