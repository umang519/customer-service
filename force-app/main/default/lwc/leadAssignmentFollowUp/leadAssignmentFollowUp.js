import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

import LEAD_OBJECT from '@salesforce/schema/Lead';
import NAME_FIELD from '@salesforce/schema/Lead.Name';
import COMPANY_FIELD from '@salesforce/schema/Lead.Company';
import EMAIL_FIELD from '@salesforce/schema/Lead.Email';
import PHONE_FIELD from '@salesforce/schema/Lead.Phone';
import STATUS_FIELD from '@salesforce/schema/Lead.Status';
import SOURCE_FIELD from '@salesforce/schema/Lead.LeadSource';
import INDUSTRY_FIELD from '@salesforce/schema/Lead.Industry';
import OWNER_FIELD from '@salesforce/schema/Lead.OwnerId';

import assignLeadToCurrentUser from '@salesforce/apex/LeadAssignmentFollowUpController.assignLeadToCurrentUser';
import createFollowUpTask from '@salesforce/apex/LeadAssignmentFollowUpController.createFollowUpTask';

export default class LeadAssignmentFollowUp extends LightningElement {
    @api recordId;

    objectApiName = LEAD_OBJECT.objectApiName;
    nameField = NAME_FIELD;
    companyField = COMPANY_FIELD;
    emailField = EMAIL_FIELD;
    phoneField = PHONE_FIELD;
    statusField = STATUS_FIELD;
    sourceField = SOURCE_FIELD;
    industryField = INDUSTRY_FIELD;
    ownerField = OWNER_FIELD;

    taskSubject = '';
    taskDate = '';
    isLoading = false;

    handleSubjectChange(event) {
        this.taskSubject = event.target.value;
    }

    handleDateChange(event) {
        this.taskDate = event.target.value;
    }

    async handleAssignToMe() {
        if (!this.recordId) {
            this.showToast('Error', 'No Lead record is available.', 'error');
            return;
        }
        this.isLoading = true;
        try {
            await assignLeadToCurrentUser({ leadIds: [this.recordId] });
            this.showToast('Success', 'Lead assigned to you.', 'success');
            getRecordNotifyChange([{ recordId: this.recordId }]);
        } catch (error) {
            this.showToast('Error', this.reduceError(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async handleCreateTask() {
        if (!this.recordId) {
            this.showToast('Error', 'No Lead record is available.', 'error');
            return;
        }
        if (!this.taskSubject) {
            this.showToast('Error', 'Please enter a task subject.', 'error');
            return;
        }
        this.isLoading = true;
        try {
            await createFollowUpTask({
                leadIds: [this.recordId],
                subject: this.taskSubject,
                activityDate: this.taskDate || null
            });
            this.showToast('Success', 'Follow-up task created.', 'success');
            this.taskSubject = '';
            this.taskDate = '';
        } catch (error) {
            this.showToast('Error', this.reduceError(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleStatusSuccess() {
        this.showToast('Success', 'Lead status updated.', 'success');
        getRecordNotifyChange([{ recordId: this.recordId }]);
    }

    handleError(event) {
        this.showToast('Error', event.detail?.message || 'Unable to save status.', 'error');
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceError(error) {
        if (typeof error === 'string') {
            return error;
        }
        if (error.body && typeof error.body.message === 'string') {
            return error.body.message;
        }
        if (error.message) {
            return error.message;
        }
        return 'An unknown error occurred.';
    }
}