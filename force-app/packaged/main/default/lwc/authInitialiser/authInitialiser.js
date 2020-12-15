import { LightningElement, track } from 'lwc';
import generateOrgAuthInitialiser from '@salesforce/apex/AuthHelper.GenerateOrgAuthInitialiser';

export default class AuthInitialiser extends LightningElement 
{
    @track authUrl;

    renderedCallback() {

        generateOrgAuthInitialiser()
        .then(result => {
            this.authUrl = result;
            
            console.log(result);
        })
        .catch(error => {
            console.log(error);
        });

    }
}