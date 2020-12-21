import { LightningElement, api } from 'lwc';
import getPicklistValues from '@salesforce/apex/OrgCheckController.getPicklistValues';

export default class Language extends LightningElement 
{
    options = [];
    @api selectedOption;
    @api flexipageRegionWidth;

    handleChange(event) {
        this.selectedOption = event.detail.value;
    }
    
    connectedCallback() {
        getPicklistValues({ objName: 'SignupRequest', fieldName: 'PreferredLanguage' })
        .then(result => {
            if(result == null || result.length == 0) {
                const item = {
                    label: 'English', 
                    value: 'English'
                };

                this.options = [ ...this.options, item ];
            }
            else {
                result.forEach(p => {
                    const item = {
                        label: p.label, 
                        value: p.value
                    };

                    this.options = [ ...this.options, item ];
                });
            }
        })
        .catch(error => {
            console.log('Error: ', error);
        });
    }
}