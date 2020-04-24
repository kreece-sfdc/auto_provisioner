public with sharing class OrgCheckController
{
    @AuraEnabled(cacheable=true)
    public static boolean checkOrgIsPBO() 
    {
        return checkOrgIsPBO('SignupRequest');
    }

    @AuraEnabled(cacheable=true)
    public static boolean checkOrgIsPBO(string objTypeName) 
    {
        try 
        {
            Type objType = Type.forName(objTypeName);

            return true;
        } 
        catch (Exception ex) 
        {
            return false;
        }
    }
}
