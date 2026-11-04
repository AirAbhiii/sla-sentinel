public with sharing class SLABoardController {

    @AuraEnabled(cacheable=true)
    public static List<Case> getAtRiskCases() {

        return [
            SELECT Id, CaseNumber, Subject, Priority,
                   SLA_Due__c, Escalation_Level__c
            FROM Case
            WHERE IsClosed = false
            AND Escalation_Level__c IN ('L1','L2','L3')
            WITH USER_MODE
            ORDER BY SLA_Due__c ASC
            LIMIT 50
        ];
    }
}