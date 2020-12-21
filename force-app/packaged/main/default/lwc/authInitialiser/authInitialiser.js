import { LightningElement, track } from 'lwc';
import generateOrgAuthInitialiser from '@salesforce/apex/AuthHelper.GenerateOrgAuthInitialiser';
import generateOrgAuthInitialiserSandbox from '@salesforce/apex/AuthHelper.GenerateOrgAuthInitialiserSandbox';

export default class AuthInitialiser extends LightningElement 
{
    @track authUrl;
    @track authUrlSandbox;

    renderedCallback() {

        generateOrgAuthInitialiser()
        .then(result => {
            this.authUrl = result;
            
            console.log(result);
        })
        .catch(error => {
            console.log(error);
        });

        generateOrgAuthInitialiserSandbox()
        .then(result => {
            this.authUrlSandbox = result;
            
            console.log(result);
        })
        .catch(error => {
            console.log(error);
        });

    }
}