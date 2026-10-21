trigger CaseTrigger on Case (before insert, before update) {
    if (Trigger.isInsert) {
        CaseTriggerHandler.onBeforeInsert(Trigger.new);
    } else if (Trigger.isUpdate) {
        CaseTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
}