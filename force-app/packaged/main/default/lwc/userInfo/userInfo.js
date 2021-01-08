import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import ID from '@salesforce/schema/Subscriber_Authentication__c.Id';
import fetchUserInfo from '@salesforce/apex/ProvisioningRequestHandler.fetchUserInfo';
import loginToOrg from '@salesforce/apex/ProvisioningRequestHandler.loginToOrg';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';


export default class UserInfo extends NavigationMixin(LightningElement) {
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

    handleClickLogin() {
        loginToOrg({ record_id: getFieldValue(this.record.data, ID) })
        .then(result => {

            if(result != '') {

                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: result
                    }
                }, true);
                
            }
        })
        .catch(error => {
            console.log('error: ');
            console.log(error);
        });
    }
}