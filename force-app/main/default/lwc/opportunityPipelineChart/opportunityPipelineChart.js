import { LightningElement, api, wire, track } from 'lwc';
import getPipelineData from '@salesforce/apex/OpportunityPipelineChartController.getPipelineData';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CHARTJS from '@salesforce/resourceUrl/chartJs';
import OPPORTUNITY_STAGE from '@salesforce/schema/Opportunity.StageName';
import OPPORTUNITY_AMOUNT from '@salesforce/schema/Opportunity.Amount';

const COLOR_PALETTE = [
    'rgba(1, 118, 211, 0.8)',
    'rgba(46, 191, 145, 0.8)',
    'rgba(250, 137, 100, 0.8)',
    'rgba(140, 100, 192, 0.8)',
    'rgba(233, 196, 106, 0.8)',
    'rgba(244, 67, 54, 0.8)',
    'rgba(0, 150, 136, 0.8)',
    'rgba(121, 85, 72, 0.8)'
];

export default class OpportunityPipelineChart extends LightningElement {
    @api recordId;

    _chartType = 'bar';
    @api get chartType() { return this._chartType; }
    set chartType(value) {
        this._chartType = value || 'bar';
        if (this.hasData && this.chartJsInitialized) {
            this.renderChart();
        }
    }

    @api stageFilter = '';

    @track chartData = [];
    @track error;
    @track isLoading = true;

    chart;
    chartJsInitialized = false;

    get hasData() { return this.chartData && this.chartData.length > 0; }
    get hasError() { return !!this.error; }
    get errorMessage() { return this.error?.body?.message || this.error?.message || 'Unknown error'; }

    @wire(getPipelineData, { stageFilter: '$stageFilter' })
    wiredPipelineData({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.error = undefined;
            this.chartData = data;
            this.initializeChart();
        } else if (error) {
            this.error = error;
            this.chartData = [];
            this.showToast('Error', this.errorMessage, 'error');
        }
    }

    async initializeChart() {
        if (!this.hasData) {
            return;
        }
        if (!this.chartJsInitialized) {
            try {
                await loadScript(this, CHARTJS);
                this.chartJsInitialized = true;
            } catch (e) {
                this.error = e;
                this.showToast('Error', 'Failed to load chart library', 'error');
                return;
            }
        }
        this.renderChart();
    }

    renderChart() {
        const canvas = this.template.querySelector('canvas.chart-canvas');
        if (!canvas) {
            return;
        }
        if (this.chart) {
            this.chart.destroy();
            this.chart = undefined;
        }
        const ctx = canvas.getContext('2d');
        const labels = this.chartData.map(row => row.stageName);
        const values = this.chartData.map(row => row.totalAmount);
        const colors = values.map((_, i) => COLOR_PALETTE[i % COLOR_PALETTE.length]);

        this.chart = new Chart(ctx, {
            type: this.chartType,
            data: {
                labels,
                datasets: [{
                    label: 'Pipeline Amount',
                    data: values,
                    backgroundColor: colors,
                    borderColor: colors.map(c => c.replace('0.8', '1')),
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: this.chartType === 'doughnut', position: 'right' },
                    tooltip: {
                        callbacks: {
                            label: (context) => {
                                const value = context.raw || 0;
                                return 'Pipeline Amount: ' + new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(value);
                            }
                        }
                    }
                }
            }
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    disconnectedCallback() {
        if (this.chart) {
            this.chart.destroy();
            this.chart = undefined;
        }
    }
}