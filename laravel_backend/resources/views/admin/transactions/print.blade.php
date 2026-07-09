@extends('layouts.print')

@section('title', 'Transaction Ledger')
@section('report_title', 'Transaction Ledger')

@section('content')
<table>
    <thead>
        <tr>
            <th width="15%">Date</th>
            <th width="15%">Trans ID</th>
            <th width="25%">Shareholder</th>
            <th width="20%">Type</th>
            <th width="15%">Amount</th>
            <th width="10%">Status</th>
        </tr>
    </thead>
    <tbody>
        @foreach($transactions as $tx)
            <tr>
                <td>{{ $tx->date->format('Y-m-d H:i') }}</td>
                <td><code style="font-size: 10px;">#{{ strtoupper(substr($tx->id, 0, 8)) }}</code></td>
                <td><strong>{{ $tx->shareholder->firstname ?? 'N/A' }} {{ $tx->shareholder->lastname ?? '' }}</strong></td>
                <td>{{ $tx->type }}</td>
                <td style="{{ $tx->amount < 0 ? 'color: #D32F2F;' : 'color: #388E3C;' }}">
                    <strong>{{ $tx->amount < 0 ? '-' : '+' }}₱{{ number_format(abs($tx->amount), 2) }}</strong>
                </td>
                <td>
                    <span class="status-badge" style="{{ $tx->status === 'completed' ? 'color: #388E3C; background: #E8F5E9;' : 'color: #F57C00; background: #FFF3E0;' }}">
                        {{ strtoupper($tx->status) }}
                    </span>
                </td>
            </tr>
        @endforeach
    </tbody>
</table>

<div style="margin-top: 30px; display: grid; grid-template-cols: 1fr 1fr; gap: 20px;">
    <div style="padding: 20px; background: #F7F8FA; border-radius: 12px;">
        <h4 style="margin: 0 0 10px 0; font-size: 12px;">VOLUME ANALYSIS</h4>
        <div style="display: flex; gap: 30px;">
            <div>
                <p style="margin: 0; font-size: 9px; color: #757575;">INFLOW</p>
                <p style="margin: 0; font-size: 14px; font-weight: 800; color: #388E3C;">₱{{ number_format($transactions->where('amount', '>', 0)->sum('amount'), 2) }}</p>
            </div>
            <div>
                <p style="margin: 0; font-size: 9px; color: #757575;">OUTFLOW</p>
                <p style="margin: 0; font-size: 14px; font-weight: 800; color: #D32F2F;">₱{{ number_format(abs($transactions->where('amount', '<', 0)->sum('amount')), 2) }}</p>
            </div>
        </div>
    </div>
    <div style="padding: 20px; border: 1px solid #EEEEEE; border-radius: 12px; display: flex; align-items: center; justify-content: center; flex-direction: column;">
        <p style="margin: 0; font-size: 10px; color: #757575; text-transform: uppercase; font-weight: bold;">Net Ledger Balance</p>
        <p style="margin: 5px 0 0; font-size: 24px; font-weight: 900; color: #FF6F00;">₱{{ number_format($transactions->sum('amount'), 2) }}</p>
    </div>
</div>
@endsection
