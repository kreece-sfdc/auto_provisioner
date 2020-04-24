import { LightningElement, track } from 'lwc';
import checkOrgIsPBO from '@salesforce/apex/OrgCheckController.checkOrgIsPBO';

export default class OrgCheck extends LightningElement 
{
    @track isPBO;

    renderedCallback() {
        checkOrgIsPBO()
        .then(result => {
            this.isPBO = result;
        })
        .catch(error => {
            //console.log(error);
        });
    }
}