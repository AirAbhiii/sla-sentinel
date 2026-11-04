public with sharing class CaseTriggerHandler {

    public static void handle(
        List<Case> newCases,
        Map<Id, Case> oldMap,
        Boolean isInsert
    ) {

        // Step 1: Custom Metadata se priority aur hours ka map banao
        Map<String, Decimal> hoursByPriority = new Map<String, Decimal>();

        for (SLA_Rule__mdt rule : SLA_Rule__mdt.getAll().values()) {
            hoursByPriority.put(
                rule.Priority__c,
                rule.Resolution_Hours__c
            );
        }

        // Step 2: Har case ke liye SLA Due Date set karo
        for (Case c : newCases) {

            Boolean priorityChanged =
                !isInsert && c.Priority != oldMap.get(c.Id).Priority;

            if (
                (isInsert || priorityChanged) &&
                c.Priority != null &&
                hoursByPriority.containsKey(c.Priority)
            ) {

                Datetime startTime = isInsert
                    ? System.now()
                    : c.CreatedDate;

                c.SLA_Due__c = startTime.addHours(
                    hoursByPriority.get(c.Priority).intValue()
                );
            }
        }
    }
}