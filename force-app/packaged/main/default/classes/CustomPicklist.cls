public with sharing class CustomPicklist 
{
    @AuraEnabled
    public string label { get; set; }
    @AuraEnabled
    public string value { get; set; }

    public CustomPicklist(string lab, string val)
    {
        if(val == null)
        {
            val = lab;
        }
        
        this.label = lab;
        this.value = val;
    }
}
