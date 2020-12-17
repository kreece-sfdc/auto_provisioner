import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import ID from '@salesforce/schema/Subscriber_Authentication__c.Id';
import fetchUserInfo from '@salesforce/apex/ProvisioningRequestHandler.fetchUserInfo';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class UserInfo extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: [ ID ] }) 
    record;

    handleClick() {
        fetchUserInfo({ record_id: getFieldValue(this.record.data, ID) })
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