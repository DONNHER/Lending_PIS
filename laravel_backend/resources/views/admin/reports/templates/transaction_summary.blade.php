@extends('layouts.print')

@section('title', 'Transaction Summary')
@section('report_title', 'Transaction Summary Analysis')

@section('content')
<div style="margin-bottom: 25px; display: grid; grid-template-cols: repeat(4, 1fr); gap: 15px;">
    <div style="background: #F7F8FA; padding: 15px; border-radius: 12px; border: 1px solid #EEEEEE;">
        <p style="margin: 0; font-size: 8px; font-weight: bold; color: #757575; text-transform: uppercase;">Total Transactions</p>
        <p style="margin: 5px 0 0; font-size: 18px; font-weight: 800;">{{ $data->count() }}</p>
    </div>
    <div style="background: #FFF7ED; padding: 15px; border-radius: 12px; border: 1px solid #FFEDD5;">
        <p style="margin: 0; font-size: 8px; font-weight: bold; color: #C2410C; text-transform: uppercase;">Net Volume</p>
        <p style="margin: 5px 0 0; font-size: 18px; font-weight: 800; color: #C2410C;">₱{{ number_format($data->sum('amount'), 2) }}</p>
    </div>
    <div style="background: #F0FDF4; padding: 15px; border-radius: 12px; border: 1px solid #DCFCE7;">
        <p style="margin: 0; font-size: 8px; font-weight: bold; color: #166534; text-transform: uppercase;">Successful</p>
        <p style="margin: 5px 0 0; font-size: 18px; font-weight: 800; color: #166534;">{{ $data->where('status', 'completed')->count() }}</p>
    </div>
    <div style="background: #FEF2F2; padding: 15px; border-radius: 12px; border: 1px solid #FEE2E2;">
        <p style="margin: 0; font-size: 8px; font-weight: bold; color: #991B1B; text-transform: uppercase;">Anomalies/Failed</p>
        <p style="margin: 5px 0 0; font-size: 18px; font-weight: 800; color: #991B1B;">{{ $data->where('status', '!=', 'completed')->count() }}</p>
    </div>
</div>

<table>
    <thead>
        <tr>
            <th width="15%">Date</th>
            <th width="15%">Ref ID</th>
            <th width="20%">Shareholder</th>
            <th width="20%">Classification</th>
            <th width="15%">Amount</th>
            <th width="15%">Status</th>
        </tr>
    </thead>
    <tbody>
        @foreach($data as $tx)
            <tr>
                <td>{{ $tx->date->format('M d, Y') }}</td>
                <td><code style="font-size: 10px;">#{{ strtoupper(substr($tx->id, 0, 8)) }}</code></td>
                <td><strong>{{ $tx->shareholder->firstname ?? 'N/A' }} {{ $tx->shareholder->lastname ?? '' }}</strong></td>
                <td>{{ $tx->type }}</td>
                <td style="{{ $tx->amount < 0 ? 'color: #D32F2F;' : 'color: #388E3C;' }}">
                    <strong>{{ $tx->amount < 0 ? '-' : '+' }}₱{{ number_format(abs($tx->amount), 2) }}</strong>
                </td>
                <td>
                    <span class="status-badge" style="{{ $tx->status === 'completed' ? 'color: #166534; background: #F0FDF4;' : 'color: #991B1B; background: #FEF2F2;' }}">
                        {{ strtoupper($tx->status) }}
                    </span>
                </td>
            </tr>
        @endforeach
    </tbody>
</table>
@endsection
