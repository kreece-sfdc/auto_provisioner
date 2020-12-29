public with sharing class ManifestCanvasUtils {

    @AuraEnabled(cacheable=true)
    public static List<sfLma__Package_Version__c> getAllPackageVersions(){
        try {
            return [SELECT ID, Name, sfLma__Package__r.Name  FROM sfLma__Package_Version__c];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true)
    public static List<sfLma__Package_Version__c> getAllManifests(){
        try {
            return [SELECT ID, Name, aprv__Description__c, aprv__Trialforce_Template__c FROM aprv__Manifest__c];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    /*
        createManifestPackage
        Takes a manifest ID and a list of package version IDs.
        Checks whether this package version has previously been added to this manifest
        If so, sets the ordinal back to 1 and adds to a list
        If not, creates a new manifest version and adds to list
        upserts new and existing records and returns them
        Called by the canvas component when a manifest package is added to the selected package list
    */
    @AuraEnabled
    public static List<aprv__Manifest_Package__c> createManifestPackages(Id manifestId, List<Id> packageVersionIds){
        List<aprv__Manifest_Package__c> manifestPackages = new List<aprv__Manifest_Package__c>();
        try {

            List<aprv__Manifest_Package__c> existingManifestPackages = [SELECT id, aprv__Manifest__c, aprv__Package_Version__c, aprv__Package_Id__c FROM aprv__Manifest_Package__c WHERE aprv__Manifest__c =: manifestId];
            Map<id, aprv__Manifest_Package__c> existingPackagesByVersionId = new Map<id, aprv__Manifest_Package__c>();
            for(aprv__Manifest_Package__c mp : existingManifestPackages){
                mp.aprv__Ordinal__c = 1;
                existingPackagesByVersionId.put(mp.aprv__Package_Version__c, mp);
            }

            for(Id pvi : packageVersionIds){

                if(existingPackagesByVersionId.get(pvi) != null){
                    manifestPackages.add(existingPackagesByVersionId.get(pvi));
                }else{
                    aprv__Manifest_Package__c mp = new aprv__Manifest_Package__c(aprv__Manifest__c = manifestId, aprv__Package_Version__c=pvi, aprv__Ordinal__c=1);
                    manifestPackages.add(mp);
                }
            }
            database.upsert(manifestPackages);
            //Query them out again to get the formula field value
            manifestPackages = [SELECT id, aprv__Manifest__c, aprv__Package_Version__c, aprv__Package_Id__c FROM aprv__Manifest_Package__c WHERE Id IN: manifestPackages];

            system.debug(manifestPackages);
            return manifestPackages;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /*
        deleteManifestPackages
        Takes a manifest ID and a list of package version IDs
        Queries for all manifest packages in that manifest for those package versions and deletes them.
        Called by the canvas component when a manifest package is removed from the selected package list
    */
    @AuraEnabled
    public static boolean deleteManifestPackages(Id manifestId, List<Id> packageVersionIds){
        try {
            List<aprv__Manifest_Package__c> manifestPackagesForDeletion = [SELECT id, aprv__Manifest__c, aprv__Package_Version__c FROM aprv__Manifest_Package__c WHERE aprv__Manifest__c =: manifestId AND aprv__Package_Version__c IN: packageVersionIds];
            database.delete(manifestPackagesForDeletion);
            return true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
