public with sharing class LeadConvertController {
    @AuraEnabled
    public static ConvertResult convertLead(Id leadId, String opportunityName) {
        if (leadId == null) {
            throw new IllegalArgumentException('Lead Id is required.');
        }

        LeadStatus convertStatus = [
            SELECT MasterLabel
            FROM LeadStatus
            WHERE IsConverted = true
            LIMIT 1
            WITH SECURITY_ENFORCED
        ];

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(leadId);
        lc.setConvertedStatus(convertStatus.MasterLabel);
        lc.setDoNotCreateOpportunity(String.isBlank(opportunityName));
        if (String.isNotBlank(opportunityName)) {
            lc.setOpportunityName(opportunityName);
        }

        Database.LeadConvertResult dbResult = Database.convertLead(lc, false);
        return new ConvertResult(dbResult);
    }

    public class ConvertResult {
        @AuraEnabled
        public Boolean isSuccess { get; set; }

        @AuraEnabled
        public String accountId { get; set; }

        @AuraEnabled
        public String contactId { get; set; }

        @AuraEnabled
        public String opportunityId { get; set; }

        @AuraEnabled
        public String errorMessage { get; set; }

        public ConvertResult(Database.LeadConvertResult dbResult) {
            this.isSuccess = dbResult.isSuccess();
            this.accountId = dbResult.getAccountId();
            this.contactId = dbResult.getContactId();
            this.opportunityId = dbResult.getOpportunityId();
            if (!dbResult.isSuccess() && dbResult.getErrors() != null && !dbResult.getErrors().isEmpty()) {
                this.errorMessage = dbResult.getErrors()[0].getMessage();
            }
        }
    }
}