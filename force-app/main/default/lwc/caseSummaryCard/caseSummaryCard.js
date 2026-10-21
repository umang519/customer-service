import { LightningElement, api } from 'lwc';
import CASE_OBJECT from '@salesforce/schema/Case';
import CASE_NUMBER from '@salesforce/schema/Case.CaseNumber';
import SUBJECT from '@salesforce/schema/Case.Subject';
import STATUS from '@salesforce/schema/Case.Status';
import PRIORITY from '@salesforce/schema/Case.Priority';
import OWNER_ID from '@salesforce/schema/Case.OwnerId';
import CREATED_DATE from '@salesforce/schema/Case.CreatedDate';

export default class CaseSummaryCard extends LightningElement {
    @api recordId;

    caseObject = CASE_OBJECT;
    caseNumber = CASE_NUMBER;
    subject = SUBJECT;
    status = STATUS;
    priority = PRIORITY;
    ownerId = OWNER_ID;
    createdDate = CREATED_DATE;
}