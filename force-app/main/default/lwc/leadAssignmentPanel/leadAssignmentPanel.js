import { LightningElement, api, wire } from 'lwc';
import { getRecord, updateRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import USER_ID from '@salesforce/user/Id';

import ID_FIELD from '@salesforce/schema/Lead.Id';
import OWNER_ID_FIELD from '@salesforce/schema/Lead.OwnerId';
import OWNER_NAME_FIELD from '@salesforce/schema/Lead.Owner.Name';
import REGION_FIELD from '@salesforce/schema/Lead.Region__c';
import INDUSTRY_FIELD from '@salesforce/schema/Lead.Industry';
import STATUS_FIELD from '@salesforce/schema/Lead.Status';

const FIELDS = [ID_FIELD, OWNER_ID_FIELD, OWNER_NAME_FIELD, REGION_FIELD, INDUSTRY_FIELD, STATUS_FIELD];

export default class LeadAssignmentPanel extends LightningElement {
    @api recordId;

    userId = USER_ID;
    isAssigning = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    lead;

    get isLoading() {
        return this.lead.data === undefined && this.lead.error === undefined;
    }

    get hasError() {
        return this.lead.error !== undefined;
    }

    get errorMessage() {
        return this.lead.error?.body?.message ?? 'Unable to load lead details.';
    }

    get ownerName() {
        return getFieldValue(this.lead.data, OWNER_NAME_FIELD) ?? '';
    }

    get ownerId() {
        return getFieldValue(this.lead.data, OWNER_ID_FIELD) ?? '';
    }

    get region() {
        return getFieldValue(this.lead.data, REGION_FIELD) ?? '';
    }

    get industry() {
        return getFieldValue(this.lead.data, INDUSTRY_FIELD) ?? '';
    }

    get status() {
        return getFieldValue(this.lead.data, STATUS_FIELD) ?? '';
    }

    get isAssignedToMe() {
        return this.ownerId && this.userId && this.ownerId === this.userId;
    }

    get isButtonDisabled() {
        return this.isAssigning || this.isAssignedToMe || !this.recordId;
    }

    async handleAssignToMe() {
        if (this.isButtonDisabled) {
            return;
        }

        this.isAssigning = true;

        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[OWNER_ID_FIELD.fieldApiName] = this.userId;

        try {
            await updateRecord({ fields });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Assigned',
                    message: 'The lead has been assigned to you.',
                    variant: 'success'
                })
            );
        } catch (error) {
            const message = error?.body?.message ?? error?.message ?? 'An error occurred while assigning the lead.';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Assignment Failed',
                    message,
                    variant: 'error'
                })
            );
        } finally {
            this.isAssigning = false;
        }
    }
}