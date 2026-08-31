import { LightningElement, api, wire } from 'lwc';
import { getRecord, updateRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import USER_ID from '@salesforce/user/Id';
import LEAD_ID from '@salesforce/schema/Lead.Id';
import LEAD_OWNER_ID from '@salesforce/schema/Lead.OwnerId';
import LEAD_OWNER_NAME from '@salesforce/schema/Lead.Owner.Name';
import LEAD_REGION from '@salesforce/schema/Lead.Region__c';
import LEAD_INDUSTRY from '@salesforce/schema/Lead.Industry';
import LEAD_STATUS from '@salesforce/schema/Lead.Status';

const FIELDS = [LEAD_OWNER_ID, LEAD_OWNER_NAME, LEAD_REGION, LEAD_INDUSTRY, LEAD_STATUS];

export default class LeadAssignmentPanel extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    lead;

    get ownerId() {
        return getFieldValue(this.lead.data, LEAD_OWNER_ID);
    }

    get ownerName() {
        return getFieldValue(this.lead.data, LEAD_OWNER_NAME);
    }

    get region() {
        return getFieldValue(this.lead.data, LEAD_REGION);
    }

    get industry() {
        return getFieldValue(this.lead.data, LEAD_INDUSTRY);
    }

    get status() {
        return getFieldValue(this.lead.data, LEAD_STATUS);
    }

    get isAssignDisabled() {
        return !this.lead.data || this.ownerId === USER_ID;
    }

    get errorMessage() {
        return this.lead.error?.body?.message || 'Unable to load lead record.';
    }

    async handleAssignToMe() {
        const fields = {};
        fields[LEAD_ID.fieldApiName] = this.recordId;
        fields[LEAD_OWNER_ID.fieldApiName] = USER_ID;

        const recordInput = { fields };

        try {
            await updateRecord(recordInput);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Lead assigned to you.',
                    variant: 'success'
                })
            );
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body?.message || 'Unable to assign lead.',
                    variant: 'error'
                })
            );
        }
    }
}
