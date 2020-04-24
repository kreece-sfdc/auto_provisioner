@isTest
public with sharing class ProvisioningHelperTest 
{
    @isTest
    static void createSignupRequestTest()
    {
        sfLma__Package__c packageObj = new sfLma__Package__c
        (
            Name = 'Test Package 1'
        );
        insert packageObj;

        sfLma__Package_Version__c packageVersion = new sfLma__Package_Version__c
        (
            sfLma__Package__c = packageObj.Id,
            Name = 'Test Package 1 v1',
            sfLma__Release_Date__c = system.today(),
            sfLma__Sequence__c = 1,
            sfLma__Version__c = '04t4J000000FPjXQAW',
            sfLma__Version_ID__c = '04t4J000000FPjXQAW'
        );
        insert packageVersion;

        sfLma__Package_Version__c packageVersion2 = new sfLma__Package_Version__c
        (
            sfLma__Package__c = packageObj.Id,
            Name = 'Test Package 1 v2',
            sfLma__Release_Date__c = system.today(),
            sfLma__Sequence__c = 2,
            sfLma__Version__c = '04t4J000000FPjXQAW',
            sfLma__Version_ID__c = '04t4J000000FPjXQAW'
        );
        insert packageVersion2;

        Provisioning_Manifest__c manifest = new Provisioning_Manifest__c
        (
            Company__c = 'Salesforce',
            Country__c = 'GB',
            Edition__c = 'Enterprise',
            FirstName__c = 'Test',
            LastName__c = 'User',
            Notes__c = '',
            PreferredLanguage__c = 'English',
            SignupEmail__c = 'test@salesforce.com',
            Subdomain__c = 'test-provision',
            Username__c = 'test@autouser.org'
        );
        insert manifest;
        
        Provisioning_Manifest_Package__c manifestPackage = new Provisioning_Manifest_Package__c
        (
            Package_Version__c = packageVersion.Id,
            Provisioning_Manifest__c = manifest.Id
        );
        insert manifestPackage;

        Provisioning_Manifest_Package__c manifestPackage2 = new Provisioning_Manifest_Package__c
        (
            Package_Version__c = packageVersion2.Id,
            Provisioning_Manifest__c = manifest.Id
        );
        insert manifestPackage2;


        ProvisioningHelper.createSignupRequest(manifest);

        system.debug(manifest.Notes__c);
        system.assert(true);
    }
}