@isTest
private with sharing class OpportunityPipelineChartControllerTest {

    @TestSetup
    static void createTestData() {
        Account testAccount = new Account(Name = 'Pipeline Test Account');
        insert testAccount;

        List<Opportunity> opportunities = new List<Opportunity>();
        for (Integer i = 0; i < 201; i++) {
            String stage;
            Integer mod = Math.mod(i, 3);
            if (mod == 0) {
                stage = 'Prospecting';
            } else if (mod == 1) {
                stage = 'Qualification';
            } else {
                stage = 'Needs Analysis';
            }
            opportunities.add(new Opportunity(
                Name = 'Test Opp ' + i,
                AccountId = testAccount.Id,
                StageName = stage,
                Amount = 1000 + i,
                CloseDate = Date.today().addDays(30)
            ));
        }

        opportunities.add(new Opportunity(
            Name = 'Closed Opp',
            AccountId = testAccount.Id,
            StageName = 'Closed Won',
            Amount = 999999,
            CloseDate = Date.today()
        ));

        Test.startTest();
        insert opportunities;
        Test.stopTest();
    }

    @isTest
    static void testGetPipelineDataPositive() {
        Test.startTest();
        List<OpportunityPipelineChartController.PipelineData> results = OpportunityPipelineChartController.getPipelineData(null);
        Test.stopTest();

        System.assert(!results.isEmpty(), 'Expected at least one aggregated pipeline row');

        Map<String, Decimal> stageToAmount = new Map<String, Decimal>();
        for (OpportunityPipelineChartController.PipelineData row : results) {
            stageToAmount.put(row.stageName, row.totalAmount);
        }

        System.assert(stageToAmount.containsKey('Prospecting'), 'Expected Prospecting stage in results');
        System.assert(stageToAmount.containsKey('Qualification'), 'Expected Qualification stage in results');
        System.assert(stageToAmount.containsKey('Needs Analysis'), 'Expected Needs Analysis stage in results');
        System.assert(!stageToAmount.containsKey('Closed Won'), 'Closed Won should be excluded from open pipeline');
    }

    @isTest
    static void testGetPipelineDataBulk() {
        Test.startTest();
        List<OpportunityPipelineChartController.PipelineData> results = OpportunityPipelineChartController.getPipelineData(null);
        Test.stopTest();

        Decimal totalAmount = 0;
        for (OpportunityPipelineChartController.PipelineData row : results) {
            totalAmount += row.totalAmount;
        }

        Decimal expectedTotal = 0;
        for (Integer i = 0; i < 201; i++) {
            expectedTotal += 1000 + i;
        }

        System.assertEquals(expectedTotal, totalAmount, 'Aggregated total should equal sum of open opportunity amounts');
    }

    @isTest
    static void testGetPipelineDataWithFilter() {
        Test.startTest();
        List<OpportunityPipelineChartController.PipelineData> results = OpportunityPipelineChartController.getPipelineData('Prospecting');
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Expected a single aggregated row when filtering by Prospecting');
        System.assertEquals('Prospecting', results[0].stageName, 'Expected stage to be Prospecting');
    }

    @isTest
    static void testGetPipelineDataNoData() {
        Test.startTest();
        List<OpportunityPipelineChartController.PipelineData> results = OpportunityPipelineChartController.getPipelineData('NonExistentStage');
        Test.stopTest();

        System.assert(results.isEmpty(), 'Expected no results for a non-matching stage filter');
    }
}