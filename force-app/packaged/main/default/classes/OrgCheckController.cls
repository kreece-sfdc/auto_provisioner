public with sharing class OrgCheckController
{
    @AuraEnabled(cacheable=true)
    public static boolean checkOrgIsPBO() 
    {
        try 
        {
            Type objType = Type.forName('SignupRequest');

            return objType != null;
        } 
        catch (Exception ex) 
        {
            return false;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<CustomPicklist> getPicklistValues(string objName, string fieldName) 
    {
        return ProvisioningHelper.getPickListValues(objName, fieldName);
    }
}
