import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ACCESS_FIELD from '@salesforce/schema/Subscriber_Authentication__c.Access__c';
import fetchUserInfo from '@salesforce/apex/AuthHelper.fetchUserInfo';

export default class UserInfo extends LightningElement {
    @api recordId;
    @track results;

    @wire(getRecord, { recordId: '$recordId', fields: [ACCESS_FIELD] }) 
    record;

    handleClick() {
        fetchUserInfo({ access_token: getFieldValue(this.record.data, ACCESS_FIELD) })
        .then(result => {
            this.results = result;
        })
        .catch(error => {
            console.log('error: ');
            console.log(error);
        });
    }
}