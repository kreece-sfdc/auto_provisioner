trigger ProvisionerTrigger on Provisioner__e (after insert) 
{
    List<Provisioner__e> items = Trigger.new;
}