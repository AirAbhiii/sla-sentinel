public with sharing class SLAEscalationBatch
    implements Database.Batchable<SObject>, Schedulable {

    // Step 1: Open Cases find karo
    public Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator([
            SELECT Id, CaseNumber, SLA_Due__c,
                   Escalation_Level__c
            FROM Case
            WHERE IsClosed = false
            AND SLA_Due__c != null
        ]);
    }

    // Step 2: Har Case ka level check karo
    public void execute(
        Database.BatchableContext bc,
        List<Case> scope
    ) {

        List<Case> toUpdate = new List<Case>();
        List<SLA_Alert__e> alerts = new List<SLA_Alert__e>();

        for (Case c : scope) {

            String current = c.Escalation_Level__c == null
                ? 'None'
                : c.Escalation_Level__c;

            String newLevel = SLAService.calculateLevel(
                c.SLA_Due__c,
                System.now()
            );

            if (newLevel != current) {

                c.Escalation_Level__c = newLevel;

                if (newLevel == 'L3') {
                    c.SLA_Breached__c = true;
                }

                toUpdate.add(c);

                alerts.add(new SLA_Alert__e(
                    Case_Id__c = c.Id,
                    Case_Number__c = c.CaseNumber,
                    Escalation_Level__c = newLevel,
                    Message__c = 'Case ' + c.CaseNumber +
                        ' escalated to ' + newLevel
                ));
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }

        if (!alerts.isEmpty()) {
            EventBus.publish(alerts);
        }
    }

    // Step 3: Batch complete hone par
    public void finish(Database.BatchableContext bc) {
    }

    // Step 4: Scheduler batch ko start karega
    public void execute(SchedulableContext sc) {

        Database.executeBatch(new SLAEscalationBatch(), 200);
    }
}