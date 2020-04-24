public with sharing class ProvisioningHelper 
{
    public static void createSignupRequest(Provisioning_Manifest__c manifest)
    {
        string client_id = '3MVG9xB_D1giir9oHPrfIWI7ADpVTlTAYCqBMnUM6p1C1sh0tvJqboDk.FErGErUR2jxbRlhJIDCvpX0M6iS_';
        string client_secret = '9E75078F6A26D48758C32106A6140F7BF15A9F0F4951F7D8725DB68CF7E22B0B';
        string callback_url = 'https://sandbox-test-developer-edition.cs80.force.com';

        try 
        {
            Type objType = Type.forName('SignupRequest');
            
            if(objType != null)
            {
                sObject signupReq = (sObject)objType.newInstance();

                signupReq.put('Company', manifest.Company__c);
                signupReq.put('ShouldConnectToEnvHub', true);
                signupReq.put('Country', manifest.Country__c);
                signupReq.put('SignupEmail', manifest.SignupEmail__c);
                signupReq.put('FirstName', manifest.FirstName__c);
                signupReq.put('LastName', manifest.LastName__c);
                signupReq.put('Subdomain', manifest.Subdomain__c);
                signupReq.put('IsSignupEmailSuppressed', true);
                signupReq.put('TrialDays', manifest.TrialDays__c);
                signupReq.put('Username', manifest.Username__c);

                if(manifest.Trialforce_Template__r != null)
                {
                    signupReq.put('TemplateId', manifest.Trialforce_Template__r.Trialforce_Template_Id__c);
                }
                else 
                {
                    signupReq.put('Edition', manifest.Edition__c);
                    signupReq.put('PreferredLanguage', manifest.PreferredLanguage__c);
                }

                signupReq.put('ConnectedAppCallbackUrl', callback_url);
                signupReq.put('ConnectedAppConsumerKey', client_id);

                if(!Test.isRunningTest())
                {
                    insert signupReq;
                }
            }
        } 
        catch (Exception ex) 
        {
            // this is an org where SignupRequest does not exist
            manifest.Notes__c = ex.getMessage();
            update manifest;
        }
    }

    public static void installPackage(Provisioning_Manifest_Package__c manifestPackage)
    {
        
    }
}
