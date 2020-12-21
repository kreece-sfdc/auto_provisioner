public with sharing class LicenceTriggerHelper 
{
    public static void HandleAfterIntert(List<sfLma__License__c> items)
    {
        for(sfLma__License__c item: items)
        {
            system.debug(item.Name);
        }
    }
}
