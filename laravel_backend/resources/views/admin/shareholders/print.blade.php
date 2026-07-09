@extends('layouts.print')

@section('title', 'Shareholders Registry')
@section('report_title', 'Shareholders Registry')

@section('content')
<table>
    <thead>
        <tr>
            <th width="5%">#</th>
            <th width="25%">Full Name</th>
            <th width="25%">Email Address</th>
            <th width="15%">Contact</th>
            <th width="15%">Total Capital</th>
            <th width="15%">Status</th>
        </tr>
    </thead>
    <tbody>
        @foreach($shareholders as $index => $s)
            <tr>
                <td>{{ $index + 1 }}</td>
                <td><strong>{{ $s->firstname }} {{ $s->lastname }}</strong></td>
                <td>{{ $s->email }}</td>
                <td>{{ $s->contact_number ?? 'N/A' }}</td>
                <td><strong>₱{{ number_format($s->total_share_capital, 2) }}</strong></td>
                <td>
                    <span class="status-badge" style="{{ $s->status === 'active' ? 'color: #388E3C; background: #E8F5E9;' : '' }}">
                        {{ strtoupper($s->status) }}
                    </span>
                </td>
            </tr>
        @endforeach
    </tbody>
</table>

<div style="margin-top: 30px; padding: 20px; background: #F7F8FA; border-radius: 12px;">
    <h4 style="margin: 0 0 10px 0; font-size: 12px; color: #212121;">SUMMARY TOTALS</h4>
    <div style="display: flex; gap: 40px;">
        <div>
            <p style="margin: 0; font-size: 9px; color: #757575;">TOTAL SHAREHOLDERS</p>
            <p style="margin: 0; font-size: 14px; font-weight: 800;">{{ $shareholders->count() }}</p>
        </div>
        <div>
            <p style="margin: 0; font-size: 9px; color: #757575;">COMBINED CAPITAL</p>
            <p style="margin: 0; font-size: 14px; font-weight: 800; color: #FF6F00;">₱{{ number_format($shareholders->sum('total_share_capital'), 2) }}</p>
        </div>
    </div>
</div>
@endsection
