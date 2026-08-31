import { LightningElement, api, wire } from 'lwc';
import { getRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import NAME_FIELD from '@salesforce/schema/Lead.Name';
import COMPANY_FIELD from '@salesforce/schema/Lead.Company';
import EMAIL_FIELD from '@salesforce/schema/Lead.Email';
import PHONE_FIELD from '@salesforce/schema/Lead.Phone';
import STATUS_FIELD from '@salesforce/schema/Lead.Status';
import SOURCE_FIELD from '@salesforce/schema/Lead.LeadSource';
import INDUSTRY_FIELD from '@salesforce/schema/Lead.Industry';
import OWNER_FIELD from '@salesforce/schema/Lead.OwnerId';
import assignLeadToCurrentUser from '@salesforce/apex/LeadFollowUpController.assignLeadToCurrentUser';
import updateLeadStatus from '@salesforce/apex/LeadFollowUpController.updateLeadStatus';
import createFollowUpTask from '@salesforce/apex/LeadFollowUpController.createFollowUpTask';

const FIELDS = [
    NAME_FIELD,
    COMPANY_FIELD,
    EMAIL_FIELD,
    PHONE_FIELD,
    STATUS_FIELD,
    SOURCE_FIELD,
    INDUSTRY_FIELD,
    OWNER_FIELD
];

export default class LeadFollowUpDashboard extends LightningElement {
    @api recordId;

    lead;
    error;
    selectedStatus;
    isLoading = false;

    nameField = NAME_FIELD;
    companyField = COMPANY_FIELD;
    emailField = EMAIL_FIELD;
    phoneField = PHONE_FIELD;
    statusField = STATUS_FIELD;
    sourceField = SOURCE_FIELD;
    industryField = INDUSTRY_FIELD;
    ownerField = OWNER_FIELD;

    statusOptions = [
        { label: 'Open - Not Contacted', value: 'Open - Not Contacted' },
        { label: 'Working - Contacted', value: 'Working - Contacted' },
        { label: 'Closed - Converted', value: 'Closed - Converted' },
        { label: 'Closed - Not Converted', value: 'Closed - Not Converted' }
    ];

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredLead({ error, data }) {
        if (data) {
            this.lead = data;
            this.error = undefined;
        } else if (error) {
            this.lead = undefined;
            this.error = error.body?.message || error.message;
        }
    }

    get isLoadingOrNoStatus() {
        return this.isLoading || !this.selectedStatus;
    }

    handleStatusChange(event) {
        this.selectedStatus = event.detail.value;
    }

    async handleAssignToMe() {
        this.isLoading = true;
        this.error = undefined;
        try {
            await assignLeadToCurrentUser({ leadIds: [this.recordId] });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Lead assigned to you.',
                    variant: 'success'
                })
            );
            await this.refreshLead();
        } catch (error) {
            this.handleError(error);
        } finally {
            this.isLoading = false;
        }
    }

    async handleUpdateStatus() {
        if (!this.selectedStatus) {
            return;
        }
        this.isLoading = true;
        this.error = undefined;
        try {
            await updateLeadStatus({
                leadIds: [this.recordId],
                newStatus: this.selectedStatus
            });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Lead status updated.',
                    variant: 'success'
                })
            );
            this.selectedStatus = undefined;
            await this.refreshLead();
        } catch (error) {
            this.handleError(error);
        } finally {
            this.isLoading = false;
        }
    }

    async handleCreateTask() {
        this.isLoading = true;
        this.error = undefined;
        try {
            await createFollowUpTask({ leadIds: [this.recordId] });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Follow-up task created.',
                    variant: 'success'
                })
            );
        } catch (error) {
            this.handleError(error);
        } finally {
            this.isLoading = false;
        }
    }

    handleError(error) {
        this.error = error.body?.message || error.message;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: this.error,
                variant: 'error'
            })
        );
    }

    async refreshLead() {
        if (this.recordId) {
            await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
        }
    }
}