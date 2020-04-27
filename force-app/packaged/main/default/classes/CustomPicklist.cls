public with sharing class CustomPicklist 
{
    @AuraEnabled
    public string label { get; set; }
    @AuraEnabled
    public string value { get; set; }

    public CustomPicklist(string lab, string val)
    {
        this.label = lab;
        this.value = val;
    }
}
