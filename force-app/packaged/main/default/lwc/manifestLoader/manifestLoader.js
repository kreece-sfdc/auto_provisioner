import { LightningElement, wire, track } from 'lwc';
import getManifests from '@salesforce/apex/ManifestCanvasUtils.getManifests';

const DELAY = 300;

export default class ManifestLoader extends LightningElement {
    @track manifests;
    @track isLoading = false;
    searchTerm = '';

    columns = [
        {type: "button", initialWidth: 100, typeAttributes: {  label: 'Load',  
                                                                name: 'load',  
                                                                title: 'Load',  
                                                                disabled: false,  
                                                                value: 'load'}},
        { label: 'Name', fieldName: 'Name' },
        { label: 'Description', fieldName: 'aprv__Description__c' },
        { label: 'Trialforce Template', fieldName: 'trialforceTemplate' },
        { label: 'Created Date', fieldName: 'CreatedDate', type: 'date'},
    ];

    /*
        getManifests
        Get the records that populate the lightning-table, 
        based on the searchTerm entered. 

        TODO Break the checkboxes into a separate search term to use in SOQL
    */
   @wire(getManifests, {searchTerm: '$searchTerm'})
   getManifests(data,error) { 
        if(data){
            this.setManifests(data.data);
            this.isLoading = false;
        } else if(error){
           console.log(error);
        }
   } 

    /*
        turn this into a proper setter
    */
    setManifests(data){
        if(data){
            var rows = data.map((item) => ({
                        ...item,
                        trialforceTemplate: ''       
                        }));
            rows.forEach(row =>{
                if(row.aprv__Trialforce_Template__c){
                    row.trialforceTemplate = row.aprv__Trialforce_Template__r.Name;
                }
            });
            this.manifests = rows;
        }
    }

    /*
        handleKeyChange
        Handle the typing of characters into the search bar and 
        set the searchTerm variable accordingly, causing
        getManifests to fire
    */
   handleKeyChange(event) {
        window.clearTimeout(this.delayTimeout);
        const thisTerm = event.target.value;
        this.isLoading = true;
        this.delayTimeout = setTimeout(() => {
            this.searchTerm = thisTerm;
        }, DELAY);
    }

    handleLoad(event){
        this.dispatchEvent(new CustomEvent('load', {
            detail: {manifestId: event.detail.row.Id}
        }));
    }

    handleCancel(){
        this.dispatchEvent(new CustomEvent('cancel'));
    }
}