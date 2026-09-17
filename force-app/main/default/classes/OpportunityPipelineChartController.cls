public with sharing class OpportunityPipelineChartController {

    @AuraEnabled(cacheable=true)
    public static List<PipelineData> getPipelineData(String stageFilter) {
        Set<String> stages = new Set<String>();
        if (String.isNotBlank(stageFilter)) {
            for (String stage : stageFilter.split(',')) {
                String trimmed = stage.trim();
                if (String.isNotBlank(trimmed)) {
                    stages.add(trimmed);
                }
            }
        }

        String query = 'SELECT StageName, SUM(Amount) totalAmt FROM Opportunity WHERE IsClosed = false';
        if (!stages.isEmpty()) {
            query += ' AND StageName IN :stages';
        }
        query += ' WITH SECURITY_ENFORCED GROUP BY StageName ORDER BY StageName';

        List<PipelineData> results = new List<PipelineData>();
        for (sObject sobj : Database.query(query)) {
            AggregateResult ar = (AggregateResult) sobj;
            String stageName = (String) ar.get('StageName');
            Decimal total = (Decimal) ar.get('totalAmt');
            results.add(new PipelineData(stageName, total == null ? 0 : total));
        }
        return results;
    }

    public class PipelineData {
        @AuraEnabled public String stageName;
        @AuraEnabled public Decimal totalAmount;

        public PipelineData(String stageName, Decimal totalAmount) {
            this.stageName = stageName;
            this.totalAmount = totalAmount;
        }
    }
}