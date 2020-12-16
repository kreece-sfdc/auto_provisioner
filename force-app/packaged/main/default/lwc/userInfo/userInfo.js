import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ACCESS_FIELD from '@salesforce/schema/Subscriber_Authentication__c.Access__c';
import fetchUserInfo from '@salesforce/apex/ProvisioningRequestHandler.fetchUserInfo';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class UserInfo extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: [ACCESS_FIELD] }) 
    record;

    handleClick() {
        fetchUserInfo({ access_token: getFieldValue(this.record.data, ACCESS_FIELD) })
        .then(result => {
            const evt = new ShowToastEvent({
                title: 'Authentication Check Response',
                message: result.Message,
                variant: result.MessageType,
            });
            this.dispatchEvent(evt);

            getRecordNotifyChange([{recordId: this.recordId}]);
        })
        .catch(error => {
            console.log('error: ');
            console.log(error);
        });
    }
}