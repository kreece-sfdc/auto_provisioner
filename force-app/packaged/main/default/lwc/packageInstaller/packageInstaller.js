import { LightningElement, track } from 'lwc';

export default class PackageInstaller extends LightningElement {
    @track manifestId;
    @track showNewManifestModal = false;
    @track selectedPackageId;

    /*
        handleCreateNewManifest
        Causes the Modal Popup to appear to enter the name of the new Manifest
    */
    handleCreateNewManifest(){
        this.showNewManifestModal = true;
    }

    /*
        handleNewManifest
        Handles updating the UI to create a new installation Manifest
    */
    handleNewManifest(event){
        this.handleCloseModals();
        this.manifestId = event.detail;
    }

    /*
        handleCloseModals
        Sets all modal pop ups to close
    */
    handleCloseModals(){
        this.showNewManifestModal = false;
    }

    handleSave(){

    }

    handleBack(){

    }
}