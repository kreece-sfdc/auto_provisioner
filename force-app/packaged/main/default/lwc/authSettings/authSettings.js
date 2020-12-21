import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import SetAuthSettings from '@salesforce/apex/AuthHelper.SetAuthSettings';
import GetAuthSettings from '@salesforce/apex/AuthHelper.GetAuthSettings';

export default class AuthSettings extends LightningElement {
    @track client_id = '';
    @track client_secret = '';
    @track callback_uri = '';

    connectedCallback() {
        GetAuthSettings()
        .then(result => {
        
            this.client_id = result.aprv__Client_Id__c;
            this.client_secret = result.aprv__Client_Secret__c;
            this.callback_uri = result.aprv__Callback_Uri__c;
    
        })
        .catch(error => {
            console.log('error: ');
            console.log(error);
        });
    }

    handleFormInputChange(event) {
        if(event.target.name == 'client_id') {
            this.client_id = event.target.value;
        }
        else if(event.target.name == 'client_secret') {
            this.client_secret = event.target.value;
        }
        else if(event.target.name == 'callback_uri') {
            this.callback_uri = event.target.value;
        }
    }

    handleClick() {
        SetAuthSettings({ client_id: this.client_id, client_secret: this.client_secret, redirect_uri: this.callback_uri })
        .then(result => {
            
            const evt = new ShowToastEvent({
                title: 'Authentication Settings',
                message: 'The authentication settings have been successfully set',
                variant: 'success',
            });
            this.dispatchEvent(evt);
    
        })
        .catch(error => {
            console.log('error: ');
            console.log(error);
        });
    }
}