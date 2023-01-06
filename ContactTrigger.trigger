/*********************************************************************************
*@Name          : ContactTrigger.trigger
*@Description   : Trigger on Contact
*@Created by    : Cagri Kilic
*@Created Date  : Jan 05 2023
*@Modification Log:
**********************************************************************************
* Version       Developer           Date                        Description
*---------------------------------------------------------------------------------
*
**********************************************************************************/
trigger ContactTrigger on Contact (before insert, before update, after insert, after update) {
    ContactTriggerHandler contactTriggerHandler = new ContactTriggerHandler();
    if (Trigger.isInsert) {
        if (Trigger.isBefore) {
            contactTriggerHandler.validatePrimaryBeforeInsert(Trigger.new);
        }
        if (Trigger.isAfter) {
            contactTriggerHandler.processPrimaryAfterInsert(Trigger.new);
        }
    }
    if (Trigger.isUpdate) {
        if (Trigger.isBefore) {
            contactTriggerHandler.validatePrimaryBeforeUpdate(Trigger.new);
        }
        if (Trigger.isAfter) {
            contactTriggerHandler.processPrimaryAfterUpdate(Trigger.new);
        }
    }
}