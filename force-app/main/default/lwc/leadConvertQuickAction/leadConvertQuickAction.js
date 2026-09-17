import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import convertLead from '@salesforce/apex/LeadConvertController.convertLead';

export default class LeadConvertQuickAction extends LightningElement {
    @api recordId;
    opportunityName = '';
    isLoading = false;

    get isConvertDisabled() {
        return this.isLoading || !this.recordId;
    }

    handleOpportunityNameChange(event) {
        this.opportunityName = event.target.value;
    }

    async handleConvert() {
        if (!this.recordId) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Record ID is not available.',
                variant: 'error'
            }));
            return;
        }

        this.isLoading = true;
        try {
            const result = await convertLead({ leadId: this.recordId, opportunityName: this.opportunityName });
            if (result.isSuccess) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Lead converted successfully.',
                    variant: 'success'
                }));
                this.dispatchEvent(new CloseActionScreenEvent());
            } else {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Conversion Failed',
                    message: result.errorMessage || 'An unknown error occurred.',
                    variant: 'error'
                }));
            }
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: error.body ? error.body.message : error.message,
                variant: 'error'
            }));
        } finally {
            this.isLoading = false;
        }
    }
}