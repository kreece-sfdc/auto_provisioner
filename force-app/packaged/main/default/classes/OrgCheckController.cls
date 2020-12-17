public with sharing class OrgCheckController
{
    @AuraEnabled(cacheable=true)
    public static boolean checkOrgIsPBO() 
    {
        return ProvisioningRequestHandler.isPBO();
    }

    @AuraEnabled(cacheable=true)
    public static List<CustomPicklist> getPicklistValues(string objName, string fieldName) 
    {
        return ProvisioningRequestHandler.getPickListValues(objName, fieldName);
    }
}
