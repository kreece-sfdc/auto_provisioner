trigger AuthHelperTrigger on AuthCode__e (after insert) 
{
    AsyncAuthHelper aah = new AsyncAuthHelper(trigger.new);
    System.enqueueJob(aah);
}