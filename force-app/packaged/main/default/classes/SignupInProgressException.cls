public with sharing class SignupInProgressException extends Exception 
{ 
    private Provisioning_Request__c inProgressRequest;

    public SignupInProgressException(Provisioning_Request__c item)
    {
        inProgressRequest = item;
    }

    public Provisioning_Request__c getRecord()
    {
        return inProgressRequest;
    }
}