@RestResource(urlMapping='/lead/v1/intake/*')
global with sharing class LeadIntakeService {
    @HttpPost
    global static LeadResponse createLead(LeadRequest request) {
        LeadResponse response = new LeadResponse();
        try {
            Lead newLead = new Lead(
                FirstName = request.firstName,
                LastName = request.lastName,
                Company = request.company,
                Email = request.email,
                Phone = request.phone,
                Industry = request.industry,
                Region__c = request.region,
                LeadSource = request.leadSource
            );
            insert newLead;

            response.success = true;
            response.leadId = newLead.Id;
        } catch (Exception e) {
            response.success = false;
            response.errorMessage = e.getMessage();
        }
        return response;
    }

    global class LeadRequest {
        global String firstName;
        global String lastName;
        global String company;
        global String email;
        global String phone;
        global String industry;
        global String region;
        global String leadSource;
    }

    global class LeadResponse {
        global Boolean success;
        global String leadId;
        global String errorMessage;
    }
}