@extends('layouts.print')

@section('title', 'Usage Statistics')
@section('report_title', 'System Usage Analytics')

@section('content')
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

<div style="margin: 20px 0; border: 1px solid #EEEEEE; border-radius: 16px; padding: 25px; background: white;">
    <h4 style="margin: 0 0 15px 0; font-size: 14px; text-align: center; color: #4B5563;">Activity Growth Trends ({{ ucfirst($period) }})</h4>
    <div style="height: 250px; position: relative;">
        <canvas id="usageChart"></canvas>
    </div>
</div>

<table>
    <thead>
        <tr>
            <th width="40%">{{ ucfirst($period) }} Time Period</th>
            <th width="30%">Interaction Volume</th>
            <th width="30%">Daily Projection (Avg)</th>
        </tr>
    </thead>
    <tbody>
        @foreach($stats as $s)
            <tr>
                <td><strong>{{ $s->label }}</strong></td>
                <td><strong>{{ number_format($s->count) }}</strong> actions</td>
                <td style="color: #757575;">{{ number_format($s->count / 30, 1) }} actions/day</td>
            </tr>
        @endforeach
    </tbody>
</table>

<div style="margin-top: 20px; padding: 15px; background: #F7F8FA; border-radius: 12px; font-size: 10px; color: #4B5563;">
    <strong>Analytic Note:</strong> This report represents the total computational interactions recorded in the system audit trail, including authentication, data modifications, and API calls for the selected timeframe.
</div>

<script>
    const ctx = document.getElementById('usageChart').getContext('2d');
    new Chart(ctx, {
        type: 'bar',
        data: {
            labels: {!! json_encode($stats->pluck('label')) !!},
            datasets: [{
                label: 'System Interactions',
                data: {!! json_encode($stats->pluck('count')) !!},
                backgroundColor: '#FF6F00',
                borderRadius: 6,
                barThickness: 30
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            animation: false, // Important for printing consistency
            plugins: {
                legend: { display: false }
            },
            scales: {
                y: { beginAtZero: true, grid: { color: '#F3F4F6' }, ticks: { font: { size: 9 } } },
                x: { grid: { display: false }, ticks: { font: { size: 9, weight: 'bold' } } }
            }
        }
    });
</script>
@endsection
