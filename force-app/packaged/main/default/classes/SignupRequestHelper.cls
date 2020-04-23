public with sharing class SignupRequestHelper 
{
    public static void createSignupRequest()
    {
        try 
        {
            Type t = Type.forName('Account');
            sObject signupReq = (sObject)t.newInstance();

            signupReq.put('Name', 'Reece');

            insert signupReq;

        } 
        catch (Exception ex) 
        {
            
        }
    }
}
