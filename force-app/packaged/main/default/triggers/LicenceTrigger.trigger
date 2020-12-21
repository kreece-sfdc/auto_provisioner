trigger LicenceTrigger on sfLma__License__c (after insert) 
{
    if(Trigger.isAfter && Trigger.isInsert)
    {
        LicenceTriggerHelper.HandleAfterIntert(Trigger.new);
    }
}