import { LightningElement, track, wire, api } from 'lwc';
import createManifestPackage from '@salesforce/apex/ManifestCanvasUtils.createManifestPackage';

//const FIELDS = ['aprv__Manifest_Package__c.aprv__Package_Version__c', 'aprv__Manifest_Package__c.aprv__Manifest__c' , 'aprv__Manifest_Package__c.Name'];

export default class ManifestCanvas extends LightningElement {
    @api manifestId;
    @track columns = {};
    showSelectPackageVersionsModal = false;
    @track allPackages = [];

    connectedCallback(){
        console.log(this.manifestId);
        this.resetColumns();
    }    

    resetColumns(){
        this.columns = [{id: '1', items: []}];
    }

    /*
        handleAddPackageVersions
        Set the showSelectPackageVersionsModal var to true
        This brings up the packageSelector cmp in a modal
        for selecting the package records
    */
    handleAddPackageVersions(){
        this.showSelectPackageVersionsModal = true;
    }

    /*
        handleCloseModals
        Sets all modal pop ups to close
    */
    handleCloseModals(){
        this.showSelectPackageVersionsModal = false;
    }

    /*
        handleOndragstart
        Takes the details of the current item and column being dragged and adds it to 
        the dataTransfer 
    */
    handleOndragstart(event) {
        event.target.style.opacity = 0.5;
        const dataTransfer = JSON.stringify({id: event.target.dataset.id, column: event.target.dataset.column});
        event.dataTransfer.setData("text/plain", dataTransfer);
    }

    /*
        handleOndragover
        Stop default dragover functionality. Without this, the items
        will return to their previous position ondrop
    */
    handleOndragover(event) {
        event.preventDefault();
    }

    /*
        handleOndragenter
        Make the dragged over object slightly see-through
        when we drag over it
    */
    handleOndragenter(event) {
        event.target.style.opacity = 0.5
    }

    /*
        handleOndragleave
        Return the dragged over object's opacity to normal when
        we exit the dragover
    */
    handleOndragleave(event) {
        event.target.style.opacity = 1.0
    }

    /*
        handleCreateNewManifestPackage
        Takes a list of Package Version IDs and calls to Apex
        method which creates Manifest packages from those IDs 
        related to this Manifest and with an ordinal of 1
    */
    handleCreateNewManifestPackage(event){
        var newPackages = event.detail.filter(x => this.allPackages.indexOf(x) === -1 );
        var removedPackages = this.allPackages.filter(x => event.detail.indexOf(x) === -1);
        console.log('newPackages');
        console.log(newPackages);
        console.log('removedPackages');
        console.log(removedPackages);

        removedPackages.forEach(pkg => {
            this.columns.forEach(col => {
                var index = this.getItemIndexByValue(pkg, col.items)
                console.log(index);
                if(index > -1){
                    col.items.splice(index, 1);
                }
            });
        });


        createManifestPackage({ manifestId: this.manifestId, packageVersionIds: newPackages })
            .then((result) => {
                this.addItems(result);
                //this.addItems(newPackages);
            })
            .catch((error) => {
                console.log(error);
            });
        this.allPackages = event.detail;
    }

    /*
        addColumn
        Adds a new row to the column object
    */
    addColumn(){
        var columnId = this.columns.length + 1;
        this.columns.push({id: columnId, items: []});
    }

    /*
        addItem
        Takes the ID of a manifest package and adds to
        first row of the column object.
    */
    addItems(manifestPackages){
        manifestPackages.forEach(element => {
            this.columns[0].items.push({id: element})
        });
        this.handleCloseModals();

        
        /*this.columns[0].items.push({id: this.currentPackageDefRecordId, 
                                    name: packageDefinition.fields.MHolt__Namespace__c.value,
                                    version: packageDefinition.fields.MHolt__Package_Version__c.value,
                                    password: packageDefinition.fields.MHolt__Password__c.value,
                                    col: 0});*/
    }

    /*
        getColumnIndexById    
        Takes an Id of an item in the columns and returns it's position
        in the array
    */
    getColumnIndexById(id){
        var idFilter = (element) => element.id == id;
        return this.columns.findIndex(idFilter);
    }

    /*
        getItemIndexByValue
        Takes an Id and an array, finds the index of the item in
        the given array and returns the index
    */
    getItemIndexByValue(id, obj){
        console.log('getitemindexbyval');
        console.log(id);
        console.log(obj);
        var idFilter = (element) => element.id == id;
        return obj.findIndex(idFilter);
    }

    /*
        handleOndrop
        Handles the moving of a package between columns (or within the same column)
        Takes the values of the dataTransfer provided in the handleOndragstart function
        Removes the item from the dragged column, adds the item to the target column 
        Shifts the other elements in that column accordingly, depending on where the item
        was dropped
    */
    handleOndrop(event) {
        event.currentTarget.style.opacity = 1.0;
        event.target.style.opacity = 1.0;

        const dataTransfer = JSON.parse(event.dataTransfer.getData('text/plain'));
        const {id: startId, column: startColumn} = dataTransfer;
        const {id: endId, column: endColumn} = event.target.dataset;

        var startColIndex = this.getColumnIndexById(startColumn);
        var endColIndex = this.getColumnIndexById(endColumn);

        var targetItemIndexInColumn = this.getItemIndexByValue(endId, this.columns[endColIndex].items);
        var itemIndexInColumn = this.getItemIndexByValue(startId, this.columns[startColIndex].items)
        var itemObject = this.columns[startColIndex].items[itemIndexInColumn];
        
        //Functionally, this doesn't matter, but from a UI perspective it looks nicer if dropping an item into empty column 
        //space goes at the end of the column, rather than being shoved into the top
        if(targetItemIndexInColumn < 0){
            targetItemIndexInColumn = this.columns[endColIndex].items.length;
        }

        //Add the item to the new column
        this.columns[endColIndex].items.splice(targetItemIndexInColumn +1, 0, itemObject);
        //Remove the item from the previous column 
        if(startColIndex == endColIndex && targetItemIndexInColumn < itemIndexInColumn){
            //If we're in the same same column and the target item is beneath the item to be dropped we will have already spliced the 
            //item below it in the list and therefore the indexes will all have shifted down compared to where the dragged item now sits
            this.columns[startColIndex].items.splice(itemIndexInColumn + 1, 1, )
        }else{
            //This would remove the item in the list before it, if applied when moving in the same column
            this.columns[startColIndex].items.splice(itemIndexInColumn, 1);
        }
    }
}