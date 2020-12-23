public with sharing class ManifestCanvasUtils {

    @AuraEnabled(cacheable=true)
    public static List<sfLma__Package_Version__c> getAllPackageVersions(){
        try {
            return [SELECT ID, Name FROM sfLma__Package_Version__c];
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
    */
    @AuraEnabled
    public static List<Id> createManifestPackage(Id manifestId, List<Id> packageVersionIds){
        List<aprv__Manifest_Package__c> manifestPackages = new List<aprv__Manifest_Package__c>();
        try {

            List<aprv__Manifest_Package__c> existingManifestPackages = [SELECT id, aprv__Manifest__c, aprv__Package_Version__c FROM aprv__Manifest_Package__c WHERE aprv__Manifest__c =: manifestId];
            Map<id, aprv__Manifest_Package__c> existingPackagesByVersionId = new Map<id, aprv__Manifest_Package__c>();
            System.debug(existingManifestPackages);
            for(aprv__Manifest_Package__c mp : existingManifestPackages){
                mp.aprv__Ordinal__c = 1;
                existingPackagesByVersionId.put(mp.aprv__Package_Version__c, mp);
                System.debug(mp);
            }

            System.debug(existingPackagesByVersionId);
            for(Id pvi : packageVersionIds){

                if(existingPackagesByVersionId.get(pvi) != null){
                    manifestPackages.add(existingPackagesByVersionId.get(pvi));
                }else{
                    aprv__Manifest_Package__c mp = new aprv__Manifest_Package__c(aprv__Manifest__c = manifestId, aprv__Package_Version__c=pvi, aprv__Ordinal__c=1);
                    manifestPackages.add(mp);
                }
            }
            database.upsert(manifestPackages);
            Set<Id> manifestPackageIds = new Map<Id,aprv__Manifest_Package__c>(manifestPackages).keySet();
            
            return new List<Id>(manifestPackageIds);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
