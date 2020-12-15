public with sharing class OrgCheckController
{
    @AuraEnabled(cacheable=true)
    public static boolean checkOrgIsPBO() 
    {
        Type objType = Type.forName('SignupRequest');

        return objType != null;
    }

    @AuraEnabled(cacheable=true)
    public static List<CustomPicklist> getPicklistValues(string objName, string fieldName) 
    {
        return ProvisioningRequestHandler.getPickListValues(objName, fieldName);
    }
}
