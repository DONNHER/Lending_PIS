@extends('layouts.print')

@section('title', 'User Activity Audit')
@section('report_title', 'User Activity Audit Report')

@section('content')
<div style="margin-bottom: 20px; font-size: 11px; color: #4B5563; display: flex; gap: 30px;">
    <div><strong>Date Range:</strong> {{ $request->start_date ?? 'All Time' }} to {{ $request->end_date ?? 'Present' }}</div>
    <div><strong>Target Role:</strong> {{ ucfirst($request->role ?? 'All Roles') }}</div>
    <div><strong>Module:</strong> {{ ucfirst($request->action_type ?? 'All Modules') }}</div>
</div>

<table>
    <thead>
        <tr>
            <th width="15%">Timestamp</th>
            <th width="20%">System User</th>
            <th width="10%">Role</th>
            <th width="15%">Action</th>
            <th width="25%">Description</th>
            <th width="15%">IP Address</th>
        </tr>
    </thead>
    <tbody>
        @forelse($data as $log)
            <tr>
                <td style="white-space: nowrap">{{ $log->created_at->format('Y-m-d H:i') }}</td>
                <td><strong>{{ $log->user->full_name ?? 'System' }}</strong><br><span style="font-size: 9px; color: #757575;">{{ $log->user->email ?? '' }}</span></td>
                <td><span class="status-badge">{{ strtoupper($log->user->role ?? 'N/A') }}</span></td>
                <td><strong>{{ $log->action }}</strong></td>
                <td style="font-size: 10px;">{{ $log->description }}</td>
                <td><code>{{ $log->ip_address }}</code></td>
            </tr>
        @empty
            <tr><td colspan="6" style="text-align: center; padding: 40px; color: #757575;">No audit records found matching the specified filters.</td></tr>
        @endforelse
    </tbody>
</table>
@endsection
