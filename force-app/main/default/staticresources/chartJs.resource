(function(global) {
    'use strict';

    function Chart(ctx, config) {
        if (typeof ctx === 'string') {
            ctx = document.getElementById(ctx);
        }
        this.canvas = ctx.canvas || ctx;
        this.ctx = this.canvas.getContext('2d');
        this.type = (config && config.type) || 'bar';
        this.data = (config && config.data) || { labels: [], datasets: [] };
        this.options = (config && config.options) || {};
        this.resizeHandler = this.resize.bind(this);
        window.addEventListener('resize', this.resizeHandler);
        this.draw();
    }

    Chart.prototype.destroy = function() {
        window.removeEventListener('resize', this.resizeHandler);
        if (this.canvas && this.ctx) {
            this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        }
    };

    Chart.prototype.update = function() {
        this.draw();
    };

    Chart.prototype.resize = function() {
        this.fitCanvas();
        this.draw();
    };

    Chart.prototype.fitCanvas = function() {
        var rect = this.canvas.getBoundingClientRect();
        var dpr = window.devicePixelRatio || 1;
        this.canvas.width = rect.width * dpr;
        this.canvas.height = rect.height * dpr;
        this.ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
        this.width = rect.width;
        this.height = rect.height;
    };

    Chart.prototype.draw = function() {
        this.fitCanvas();
        this.ctx.clearRect(0, 0, this.width, this.height);
        if (this.type === 'doughnut') {
            this.drawDoughnut();
        } else {
            this.drawBar();
        }
    };

    Chart.prototype.getColors = function(count) {
        var palette = ['#0176D3', '#2EBF91', '#FA8964', '#8C64C0', '#E9C46A', '#F44336', '#009688', '#795548'];
        var colors = [];
        for (var i = 0; i < count; i++) {
            colors.push(palette[i % palette.length]);
        }
        return colors;
    };

    Chart.prototype.formatValue = function(value) {
        var callback = this.options && this.options.plugins && this.options.plugins.tooltip && this.options.plugins.tooltip.callbacks && this.options.plugins.tooltip.callbacks.label;
        if (typeof callback === 'function') {
            return callback({ raw: value, dataset: this.data.datasets[0] });
        }
        return String(value);
    };

    Chart.prototype.drawBar = function() {
        var labels = this.data.labels || [];
        var dataset = this.data.datasets && this.data.datasets[0] ? this.data.datasets[0] : { data: [] };
        var values = dataset.data || [];
        if (values.length === 0) {
            return;
        }
        var colors = dataset.backgroundColor || this.getColors(values.length);
        var max = Math.max.apply(null, values) * 1.1 || 1;
        var padding = 30;
        var chartBottom = this.height - padding;
        var chartTop = padding;
        var chartLeft = padding + 30;
        var chartRight = this.width - padding;
        var chartWidth = Math.max(0, chartRight - chartLeft);
        var chartHeight = Math.max(0, chartBottom - chartTop);
        var slotWidth = values.length > 0 ? chartWidth / values.length : 0;
        var barWidth = slotWidth * 0.6;
        var gap = slotWidth * 0.4;

        this.ctx.strokeStyle = '#dddbda';
        this.ctx.lineWidth = 1;
        this.ctx.beginPath();
        this.ctx.moveTo(chartLeft, chartTop);
        this.ctx.lineTo(chartLeft, chartBottom);
        this.ctx.lineTo(chartRight, chartBottom);
        this.ctx.stroke();

        this.ctx.fillStyle = '#706e6b';
        this.ctx.font = '10px sans-serif';
        this.ctx.textAlign = 'right';
        this.ctx.textBaseline = 'middle';
        var ticks = 5;
        for (var i = 0; i <= ticks; i++) {
            var value = max * i / ticks;
            var y = chartBottom - (value / max) * chartHeight;
            this.ctx.fillText(this.formatValue(value), chartLeft - 6, y);
            this.ctx.beginPath();
            this.ctx.moveTo(chartLeft, y);
            this.ctx.lineTo(chartRight, y);
            this.ctx.strokeStyle = '#f3f2f2';
            this.ctx.stroke();
        }

        for (var j = 0; j < values.length; j++) {
            var x = chartLeft + gap / 2 + j * (barWidth + gap);
            var h = (values[j] / max) * chartHeight;
            var y = chartBottom - h;
            this.ctx.fillStyle = Array.isArray(colors) ? colors[j % colors.length] : colors;
            this.ctx.fillRect(x, y, barWidth, h);

            this.ctx.fillStyle = '#3e3e3c';
            this.ctx.textAlign = 'center';
            this.ctx.textBaseline = 'top';
            this.ctx.fillText(labels[j] || '', x + barWidth / 2, chartBottom + 4);
        }
    };

    Chart.prototype.drawDoughnut = function() {
        var dataset = this.data.datasets && this.data.datasets[0] ? this.data.datasets[0] : { data: [] };
        var values = dataset.data || [];
        if (values.length === 0) {
            return;
        }
        var colors = dataset.backgroundColor || this.getColors(values.length);
        var total = values.reduce(function(a, b) { return a + b; }, 0);
        var cx = this.width / 2;
        var cy = this.height / 2;
        var radius = Math.min(this.width, this.height) / 2 - 20;
        var innerRadius = radius * 0.55;
        var start = -Math.PI / 2;

        for (var i = 0; i < values.length; i++) {
            var slice = total ? (values[i] / total) * 2 * Math.PI : 0;
            this.ctx.beginPath();
            this.ctx.arc(cx, cy, radius, start, start + slice);
            this.ctx.arc(cx, cy, innerRadius, start + slice, start, true);
            this.ctx.closePath();
            this.ctx.fillStyle = Array.isArray(colors) ? colors[i % colors.length] : colors;
            this.ctx.fill();
            start += slice;
        }

        var labels = this.data.labels || [];
        var legendX = cx + radius + 10;
        var legendY = cy - (values.length * 12) / 2;
        this.ctx.textAlign = 'left';
        this.ctx.textBaseline = 'middle';
        this.ctx.font = '11px sans-serif';
        for (var k = 0; k < values.length; k++) {
            this.ctx.fillStyle = Array.isArray(colors) ? colors[k % colors.length] : colors;
            this.ctx.fillRect(legendX, legendY - 5, 10, 10);
            this.ctx.fillStyle = '#3e3e3c';
            this.ctx.fillText((labels[k] || '') + ' ' + this.formatValue(values[k]), legendX + 14, legendY);
            legendY += 18;
        }
    };

    global.Chart = Chart;
})(window);