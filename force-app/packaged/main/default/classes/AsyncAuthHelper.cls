public with sharing class AsyncAuthHelper implements Queueable, Database.AllowsCallouts 
{
    private List<AuthCode__e> EventItems { get; set; }

    public AsyncAuthHelper(List<AuthCode__e> items) 
    {
        EventItems = items;
    }

    public void execute(QueueableContext context) 
    {
        AuthHelper.handleEvent(EventItems);
    }
}
