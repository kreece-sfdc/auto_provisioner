public with sharing class OrgCheckController
{
    @AuraEnabled(cacheable=true)
    public static boolean checkOrgIsPBO() 
    {
        return checkOrgIsPBO('SignupRequest');
    }

    @AuraEnabled(cacheable=true)
    public static boolean checkOrgIsPBO(string objType) 
    {
        return Type.forName(objType) != null;
    }
}
