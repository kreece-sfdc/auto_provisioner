@isTest
public with sharing class ProvisioningRequestHandlerTest
{
    @isTest
    static void createSignupRequestTest()
    {
        sfLma__Package__c packageObj = new sfLma__Package__c
        (
            Name = 'Test Package 1',
            Namespace__c = 'aprv'
        );
        insert packageObj;

        sfLma__Package_Version__c packageVersion = new sfLma__Package_Version__c
        (
            sfLma__Package__c = packageObj.Id,
            Name = 'Test Package 1 v1',
            sfLma__Release_Date__c = system.today(),
            sfLma__Sequence__c = 1,
            sfLma__Version__c = '04t4J000000FPjXQAW',
            sfLma__Version_ID__c = '04t4J000000FPjXQAW',
            Package_Version_Password__c = ''
        );
        insert packageVersion;

        sfLma__Package_Version__c packageVersion2 = new sfLma__Package_Version__c
        (
            sfLma__Package__c = packageObj.Id,
            Name = 'Test Package 1 v2',
            sfLma__Release_Date__c = system.today(),
            sfLma__Sequence__c = 2,
            sfLma__Version__c = '04t4J000000FPjXQAW',
            sfLma__Version_ID__c = '04t4J000000FPjXQAW',
            Package_Version_Password__c = ''
        );
        insert packageVersion2;

        Trialforce_Template__c template = new Trialforce_Template__c
        (
            Trialforce_Template_Id__c = 'TTID001'
        );
        insert template;

        Manifest__c manifest = new Manifest__c
        (
            Name = 'Test',
            Trialforce_Template__c = template.Id
        );
        insert manifest;

        Manifest_Package__c mp1 = new Manifest_Package__c
        (
            Manifest__c = manifest.Id,
            Ordinal__c = 1,
            Package__c = packageObj.Id,
            Package_Version__c = packageVersion.Id
        );
        insert mp1;

        Manifest_Package__c mp2 = new Manifest_Package__c
        (
            Manifest__c = manifest.Id,
            Ordinal__c = 2,
            Package__c = packageObj.Id,
            Package_Version__c = packageVersion2.Id
        );
        insert mp2;

        ProvisioningRequest pr = new ProvisioningRequest();
        pr.ManifestId = manifest.Id;
        pr.Company = 'Test';
        pr.Country = 'GB';
        pr.FirstName = 'Test';
        pr.LastName = 'Test';
        pr.Notes = 'Some notes...';
        pr.Edition = 'Partner Enterprise';
        pr.Language = 'English';
        pr.Email = 'test@salesforce.com';
        pr.Subdomain = 'test-trial';
        pr.TrialDays = 30;
        pr.Username = 'test@testtrial.org';

        ProvisioningRequestHandler.CreateProvisioningRequest(new List<ProvisioningRequest> { pr });

        List<Provisioning_Request__c> requests = [SELECT Id FROM Provisioning_Request__c];
        system.assertNotEquals(0, requests.size());
    }

    @isTest
    static void GetPicklistValuesTest()
    {
        List<CustomPicklist> respList = OrgCheckController.getPicklistValues('SignupRequest', 'Edition');

        system.assertNotEquals(null, respList);
    }

    @isTest
    static void checkOrgIsPBOTest()
    {
        boolean resp = OrgCheckController.checkOrgIsPBO();
        
        system.assertNotEquals(null, resp);
    }

    @isTest
    static void CreateOrgSignupRequestTest()
    {
        sfLma__Package__c packageObj = new sfLma__Package__c
        (
            Name = 'Test Package 1',
            Namespace__c = 'aprv'
        );
        insert packageObj;

        sfLma__Package_Version__c packageVersion = new sfLma__Package_Version__c
        (
            sfLma__Package__c = packageObj.Id,
            Name = 'Test Package 1 v1',
            sfLma__Release_Date__c = system.today(),
            sfLma__Sequence__c = 1,
            sfLma__Version__c = '04t4J000000FPjXQAW',
            sfLma__Version_ID__c = '04t4J000000FPjXQAW',
            Package_Version_Password__c = ''
        );
        insert packageVersion;

        sfLma__Package_Version__c packageVersion2 = new sfLma__Package_Version__c
        (
            sfLma__Package__c = packageObj.Id,
            Name = 'Test Package 1 v2',
            sfLma__Release_Date__c = system.today(),
            sfLma__Sequence__c = 2,
            sfLma__Version__c = '04t4J000000FPjXQAW',
            sfLma__Version_ID__c = '04t4J000000FPjXQAW',
            Package_Version_Password__c = ''
        );
        insert packageVersion2;

        Trialforce_Template__c template = new Trialforce_Template__c
        (
            Trialforce_Template_Id__c = 'TTID001'
        );
        insert template;

        Manifest__c manifest = new Manifest__c
        (
            Name = 'Test',
            Trialforce_Template__c = template.Id
        );
        insert manifest;

        Manifest_Package__c mp1 = new Manifest_Package__c
        (
            Manifest__c = manifest.Id,
            Ordinal__c = 1,
            Package__c = packageObj.Id,
            Package_Version__c = packageVersion.Id
        );
        insert mp1;

        Manifest_Package__c mp2 = new Manifest_Package__c
        (
            Manifest__c = manifest.Id,
            Ordinal__c = 2,
            Package__c = packageObj.Id,
            Package_Version__c = packageVersion2.Id
        );
        insert mp2;

        ProvisioningRequest pr = new ProvisioningRequest();
        pr.ManifestId = manifest.Id;
        pr.Company = 'Test';
        pr.Country = 'GB';
        pr.FirstName = 'Test';
        pr.LastName = 'Test';
        pr.Notes = 'Some notes...';
        pr.Edition = 'Partner Enterprise';
        pr.Language = 'English';
        pr.Email = 'test@salesforce.com';
        pr.Subdomain = 'test-trial';
        pr.TrialDays = 30;
        pr.Username = 'test@testtrial.org';

        ProvisioningRequestHandler.CreateProvisioningRequest(new List<ProvisioningRequest> { pr });

        List<Provisioning_Request__c> requests = [SELECT Id, Company__c, Country__c, FirstName__c, LastName__c, Notes__c, Org_Id__c, PreferredEdition__c, PreferredLanguage__c, SignupEmail__c, Status__c, Subdomain__c, TrialDays__c, Trialforce_Template_Id__c, Username__c FROM Provisioning_Request__c];
        
        ProvisioningRequestHandler.CreateOrgSignupRequest(requests[0]);
    }

    @isTest
    static void CreateOrgSignupRequestNoTrialforceTest()
    {
        sfLma__Package__c packageObj = new sfLma__Package__c
        (
            Name = 'Test Package 1',
            Namespace__c = 'aprv'
        );
        insert packageObj;

        sfLma__Package_Version__c packageVersion = new sfLma__Package_Version__c
        (
            sfLma__Package__c = packageObj.Id,
            Name = 'Test Package 1 v1',
            sfLma__Release_Date__c = system.today(),
            sfLma__Sequence__c = 1,
            sfLma__Version__c = '04t4J000000FPjXQAW',
            sfLma__Version_ID__c = '04t4J000000FPjXQAW',
            Package_Version_Password__c = ''
        );
        insert packageVersion;

        sfLma__Package_Version__c packageVersion2 = new sfLma__Package_Version__c
        (
            sfLma__Package__c = packageObj.Id,
            Name = 'Test Package 1 v2',
            sfLma__Release_Date__c = system.today(),
            sfLma__Sequence__c = 2,
            sfLma__Version__c = '04t4J000000FPjXQAW',
            sfLma__Version_ID__c = '04t4J000000FPjXQAW',
            Package_Version_Password__c = ''
        );
        insert packageVersion2;

        Manifest__c manifest = new Manifest__c
        (
            Name = 'Test'
        );
        insert manifest;

        Manifest_Package__c mp1 = new Manifest_Package__c
        (
            Manifest__c = manifest.Id,
            Ordinal__c = 1,
            Package__c = packageObj.Id,
            Package_Version__c = packageVersion.Id
        );
        insert mp1;

        Manifest_Package__c mp2 = new Manifest_Package__c
        (
            Manifest__c = manifest.Id,
            Ordinal__c = 2,
            Package__c = packageObj.Id,
            Package_Version__c = packageVersion2.Id
        );
        insert mp2;

        ProvisioningRequest pr = new ProvisioningRequest();
        pr.ManifestId = manifest.Id;
        pr.Company = 'Test';
        pr.Country = 'GB';
        pr.FirstName = 'Test';
        pr.LastName = 'Test';
        pr.Notes = 'Some notes...';
        pr.Edition = 'Partner Enterprise';
        pr.Language = 'English';
        pr.Email = 'test@salesforce.com';
        pr.Subdomain = 'test-trial';
        pr.TrialDays = 30;
        pr.Username = 'test@testtrial.org';

        ProvisioningRequestHandler.CreateProvisioningRequest(new List<ProvisioningRequest> { pr });

        List<Provisioning_Request__c> requests = [SELECT Id, Company__c, Country__c, FirstName__c, LastName__c, Notes__c, Org_Id__c, PreferredEdition__c, PreferredLanguage__c, SignupEmail__c, Status__c, Subdomain__c, TrialDays__c, Trialforce_Template_Id__c, Username__c FROM Provisioning_Request__c];
        
        ProvisioningRequestHandler.CreateOrgSignupRequest(requests[0]);
    }
}