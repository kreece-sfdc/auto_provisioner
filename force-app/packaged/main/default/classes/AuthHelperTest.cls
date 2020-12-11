@isTest
public with sharing class AuthHelperTest 
{
    @isTest
    static void AsyncAuthHelperTest()
    {
        /*Test.setMock(HttpCalloutMock.class, new AuthCalloutMock());

        Test.startTest();
        AuthCode__e code = new AuthCode__e
        (
            Code__c = 'abc123'
        );
        EventBus.publish(code);
        Test.stopTest();

        system.assert(true);*/
    }

    @isTest
    static void FetchUserInfoTest()
    {
        Test.setMock(HttpCalloutMock.class, new AuthCalloutMock());
        AuthHelper.fetchUserInfo('access_token');
    }
}
