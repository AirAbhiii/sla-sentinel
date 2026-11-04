trigger CaseTrigger on Case (before insert, before update) {
    CaseTriggerHandler.handle(Trigger.new, Trigger.oldMap, Trigger.isInsert);
}