import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LEAD_OBJECT from '@salesforce/schema/Lead';
import NAME_FIELD from '@salesforce/schema/Lead.Name';
import COMPANY_FIELD from '@salesforce/schema/Lead.Company';
import TITLE_FIELD from '@salesforce/schema/Lead.Title';
import EMAIL_FIELD from '@salesforce/schema/Lead.Email';
import PHONE_FIELD from '@salesforce/schema/Lead.Phone';
import INDUSTRY_FIELD from '@salesforce/schema/Lead.Industry';
import LEAD_SOURCE_FIELD from '@salesforce/schema/Lead.LeadSource';
import STATUS_FIELD from '@salesforce/schema/Lead.Status';
import RATING_FIELD from '@salesforce/schema/Lead.Rating';

export default class LeadQualificationPanel extends LightningElement {
    @api recordId;

    leadObject = LEAD_OBJECT;
    nameField = NAME_FIELD;
    companyField = COMPANY_FIELD;
    titleField = TITLE_FIELD;
    emailField = EMAIL_FIELD;
    phoneField = PHONE_FIELD;
    industryField = INDUSTRY_FIELD;
    leadSourceField = LEAD_SOURCE_FIELD;
    statusField = STATUS_FIELD;
    ratingField = RATING_FIELD;

    handleSubmit(event) {
        event.preventDefault();
        const fields = event.detail.fields;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleSuccess() {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Lead qualification updated successfully.',
                variant: 'success'
            })
        );
    }

    handleError(event) {
        let message = 'An error occurred while saving the lead.';
        if (event.detail && event.detail.detail) {
            message = event.detail.detail;
        } else if (event.detail && event.detail.message) {
            message = event.detail.message;
        }

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: message,
                variant: 'error',
                mode: 'sticky'
            })
        );
    }
}