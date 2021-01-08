import { api, LightningElement, track, wire } from 'lwc';
import getAllPackageVersions from '@salesforce/apex/ManifestCanvasUtils.getAllPackageVersions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'


export default class PackageSelector extends LightningElement {
    allPackageVersions;
    @api selectedPackageVersions;
    @track showPackageCreationModal = false;
    @track showPackageVersionCreationModal = false;
    newPackageId;
    newPackageVersionId;
    

    connectedCallback(){
        this.getPackageVersions();
    }

    getPackageVersions(){
        getAllPackageVersions()
        .then((result) => {
            this.allPackageVersions = [];
            result.forEach(element => {
                this.allPackageVersions.push({label: element.sfLma__Package__r.Name + ': ' + element.Name, value: element.Id});                    
            });
        });
    }

    handleAddPackageWindow(){
        this.showPackageCreationModal = true;
    }

    handleChange(event){
        this.selectedPackageVersions = event.detail.value;
    }

    handleCancel(){
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    handleDone(){
        this.dispatchEvent(new CustomEvent('success', {detail: this.selectedPackageVersions}));
    }

    handleNewPackageCreation(event){
        this.newPackageId = event.detail.id;
        this.handleCloseModals();
        this.showPackageVersionCreationModal = true;
        
        var title = 'Package Created!';
        var message = 'Create Package Version to add it to your manifest';
        this.showToast(title, message, 'success');
    }

    handleNewPackageVersionCreation(event){
        console.log(event.detail);
        console.log(event.detail.id);
        if(event.detail){
            this.newPackageVersionId = event.detail.id;
            this.getPackageVersions();
            this.handleCloseModals();

            var title = 'Package Version Created!';
            var message = 'Package Version now available to add to your manifest';
            this.showToast(title, message, 'success');
        }
    }
    
    handleError(event){
        console.log(event);
        this.showToast('Error' , event.detail + '. Ensure a Package Version ID (04t...) has been entered.', 'error');
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    /*
        handleCloseModals
        Sets all modal pop ups to close
    */
   handleCloseModals(){
    this.showPackageCreationModal = false;
    this.showPackageVersionCreationModal = false;
}


}