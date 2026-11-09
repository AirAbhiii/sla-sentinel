@IsTest
private class SLASentinelTest {

    // Helper: test case banane ka chhota method
    private static Case makeCase(String priority) {
        return new Case(Subject = 'Test ' + priority, Priority = priority, Origin = 'Web');
    }

    // ---------- Trigger tests ----------

    @IsTest
    static void slaDueIsSetOnInsert() {
        Case c = makeCase('High');
        Test.startTest();
        insert c;
        Test.stopTest();

        Case result = [SELECT SLA_Due__c FROM Case WHERE Id = :c.Id];
        System.assertNotEquals(null, result.SLA_Due__c, 'SLA due date should be set');
    }

    @IsTest
    static void bulkInsertWorks() {
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < 200; i++) {
            cases.add(makeCase('Medium'));
        }
        Test.startTest();
        insert cases;
        Test.stopTest();

        System.assertEquals(200, [SELECT COUNT() FROM Case WHERE SLA_Due__c != null],
            'All 200 cases should get an SLA due date');
    }

    @IsTest
    static void slaDueChangesWhenPriorityChanges() {
        Case c = makeCase('High');
        insert c;
        Datetime highDue = [SELECT SLA_Due__c FROM Case WHERE Id = :c.Id].SLA_Due__c;

        c.Priority = 'Low';
        Test.startTest();
        update c;
        Test.stopTest();

        Datetime lowDue = [SELECT SLA_Due__c FROM Case WHERE Id = :c.Id].SLA_Due__c;
        System.assert(lowDue > highDue, 'Low priority should have a later deadline than High');
    }

    // ---------- Service test ----------

    @IsTest
    static void levelCalculation() {
        Datetime now = System.now();
        System.assertEquals('L3', SLAService.calculateLevel(now.addMinutes(-5), now));
        System.assertEquals('L2', SLAService.calculateLevel(now.addMinutes(30), now));
        System.assertEquals('L1', SLAService.calculateLevel(now.addMinutes(90), now));
        System.assertEquals('None', SLAService.calculateLevel(now.addHours(5), now));
    }

    // ---------- Batch tests ----------

    @IsTest
    static void batchEscalatesBreachedCase() {
        Case c = makeCase('High');
        insert c;
        c.SLA_Due__c = System.now().addHours(-1);
        update c;

        Test.startTest();
        Database.executeBatch(new SLAEscalationBatch());
        Test.stopTest();

        Case result = [SELECT Escalation_Level__c, SLA_Breached__c FROM Case WHERE Id = :c.Id];
        System.assertEquals('L3', result.Escalation_Level__c);
        System.assertEquals(true, result.SLA_Breached__c);
    }

    @IsTest
    static void batchSetsL1ForCaseNearDeadline() {
        Case c = makeCase('High');
        insert c;
        c.SLA_Due__c = System.now().addMinutes(90);
        update c;

        Test.startTest();
        Database.executeBatch(new SLAEscalationBatch());
        Test.stopTest();

        Case result = [SELECT Escalation_Level__c, SLA_Breached__c FROM Case WHERE Id = :c.Id];
        System.assertEquals('L1', result.Escalation_Level__c);
        System.assertEquals(false, result.SLA_Breached__c);
    }

    @IsTest
    static void batchLeavesSafeCaseAlone() {
        Case c = makeCase('Low');
        insert c;   // deadline 24 ghante door hai

        Test.startTest();
        Database.executeBatch(new SLAEscalationBatch());
        Test.stopTest();

        Case result = [SELECT Escalation_Level__c FROM Case WHERE Id = :c.Id];
        System.assert(result.Escalation_Level__c == null || result.Escalation_Level__c == 'None',
            'Safe case should not be escalated');
    }

    @IsTest
    static void batchSkipsClosedCases() {
        Case c = makeCase('High');
        insert c;
        c.SLA_Due__c = System.now().addHours(-1);
        c.Status = 'Closed';
        update c;

        Test.startTest();
        Database.executeBatch(new SLAEscalationBatch());
        Test.stopTest();

        Case result = [SELECT Escalation_Level__c FROM Case WHERE Id = :c.Id];
        System.assert(result.Escalation_Level__c == null || result.Escalation_Level__c == 'None',
            'Closed case should be skipped');
    }

    @IsTest
    static void schedulerRunsBatch() {
        Test.startTest();
        String jobId = System.schedule('SLA Test Job', '0 0 * * * ?', new SLAEscalationBatch());
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Job should be scheduled');
    }

    // ---------- LWC controller test ----------

    @IsTest
    static void controllerReturnsAtRiskCases() {
        Case c = makeCase('High');
        insert c;
        c.SLA_Due__c = System.now().addHours(-1);
        update c;
        Database.executeBatch(new SLAEscalationBatch());
        Test.startTest();
        Test.stopTest();

        List<Case> result = SLABoardController.getAtRiskCases();
        System.assertEquals(1, result.size(), 'Board should show the breached case');
    }
}