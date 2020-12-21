@isTest
public with sharing class LicenceTriggerHelperTest 
{
    @isTest
    static void HandleAfterIntertTest()
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

        List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType WHERE sObjectType = 'sfLma__License__c' AND IsActive = TRUE AND Name = 'Trial'];

        sfLma__License__c licence = new sfLma__License__c
        (
            RecordTypeId = recordTypes.get(0).Id,
            sfLma__Package__c = packageObj.Id,
            sfLma__Package_Version__c = packageVersion.Id
        );
        insert licence;

        List<sfLma__License__c> licences = [SELECT Id, Name FROM sfLma__License__c];
        system.assertNotEquals(0, licences.size());
    }
}
