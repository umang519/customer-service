import { LightningElement, api, wire } from 'lwc';
import { getRecord, updateRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Id from '@salesforce/user/Id';
import APPROVAL_STATUS_FIELD from '@salesforce/schema/Opportunity.Approval_Status__c';
import STAGE_NAME_FIELD from '@salesforce/schema/Opportunity.StageName';
import OWNER_ID_FIELD from '@salesforce/schema/Opportunity.OwnerId';
import MANAGER_ID_FIELD from '@salesforce/schema/User.ManagerId';

const OPPORTUNITY_FIELDS = [APPROVAL_STATUS_FIELD, STAGE_NAME_FIELD, OWNER_ID_FIELD];

export default class OpportunityApprovalStatus extends LightningElement {
    @api recordId;
    currentUserId = Id;
    approvalStatus;
    ownerId;
    isManager = false;
    isLoading = false;

    @wire(getRecord, { recordId: '$recordId', fields: OPPORTUNITY_FIELDS })
    wiredOpportunity({ error, data }) {
        if (data) {
            this.approvalStatus = getFieldValue(data, APPROVAL_STATUS_FIELD) || 'Not Required';
            this.ownerId = getFieldValue(data, OWNER_ID_FIELD);
        } else if (error) {
            this.approvalStatus = undefined;
            this.ownerId = undefined;
        }
    }

    @wire(getRecord, { recordId: '$ownerId', fields: [MANAGER_ID_FIELD] })
    wiredOwner({ error, data }) {
        if (data) {
            const managerId = getFieldValue(data, MANAGER_ID_FIELD);
            this.isManager = managerId === this.currentUserId;
        } else if (error) {
            this.isManager = false;
        }
    }

    get showActions() {
        return this.isManager && this.approvalStatus !== 'Approved' && this.approvalStatus !== 'Rejected';
    }

    get statusClass() {
        switch (this.approvalStatus) {
            case 'Pending':
                return 'slds-badge slds-theme_warning';
            case 'Approved':
                return 'slds-badge slds-theme_success';
            case 'Rejected':
                return 'slds-badge slds-theme_error';
            default:
                return 'slds-badge';
        }
    }

    handleApprove() {
        this.updateApproval('Approved');
    }

    handleReject() {
        this.updateApproval('Rejected', 'Closed Lost');
    }

    async updateApproval(status, stageName) {
        this.isLoading = true;
        const fields = { Id: this.recordId };
        fields[APPROVAL_STATUS_FIELD.fieldApiName] = status;
        if (stageName) {
            fields[STAGE_NAME_FIELD.fieldApiName] = stageName;
        }
        try {
            await updateRecord({ fields });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Opportunity ' + status.toLowerCase() + '.',
                    variant: 'success'
                })
            );
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.reduceErrors(error),
                    variant: 'error'
                })
            );
        } finally {
            this.isLoading = false;
        }
    }

    reduceErrors(error) {
        if (!error || !error.body) {
            return error && error.message ? error.message : 'Unknown error';
        }
        if (Array.isArray(error.body)) {
            return error.body.map((e) => e.message).join(', ');
        }
        return error.body.message || error.message || 'Unknown error';
    }
}