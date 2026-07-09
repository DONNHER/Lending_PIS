@extends('layouts.dashboard')

@section('title', 'System Settings')
@section('header_title', 'System Configuration')

@section('content')
<div class="max-w-6xl mx-auto space-y-8" x-data="{ activeTab: 'branding' }">
    <!-- Settings Navigation -->
    <div class="flex overflow-x-auto gap-2 bg-white p-2 rounded-2xl border border-[#F0F1F5] shadow-sm no-scrollbar">
        <button @click="activeTab = 'branding'" :class="activeTab === 'branding' ? 'bg-primary text-white' : 'text-text-muted hover:bg-gray-50'" class="px-6 py-2.5 rounded-xl text-xs font-bold transition-all whitespace-nowrap">Branding</button>
        <button @click="activeTab = 'interest'" :class="activeTab === 'interest' ? 'bg-primary text-white' : 'text-text-muted hover:bg-gray-50'" class="px-6 py-2.5 rounded-xl text-xs font-bold transition-all whitespace-nowrap">Lending Policy</button>
        <button @click="activeTab = 'security'" :class="activeTab === 'security' ? 'bg-primary text-white' : 'text-text-muted hover:bg-gray-50'" class="px-6 py-2.5 rounded-xl text-xs font-bold transition-all whitespace-nowrap">Security</button>
        <button @click="activeTab = 'email'" :class="activeTab === 'email' ? 'bg-primary text-white' : 'text-text-muted hover:bg-gray-50'" class="px-6 py-2.5 rounded-xl text-xs font-bold transition-all whitespace-nowrap">Email (SMTP)</button>
        <button @click="activeTab = 'backup'" :class="activeTab === 'backup' ? 'bg-primary text-white' : 'text-text-muted hover:bg-gray-50'" class="px-6 py-2.5 rounded-xl text-xs font-bold transition-all whitespace-nowrap">Backup & Data</button>
        <button @click="activeTab = 'maintenance'" :class="activeTab === 'maintenance' ? 'bg-primary text-white' : 'text-text-muted hover:bg-gray-50'" class="px-6 py-2.5 rounded-xl text-xs font-bold transition-all whitespace-nowrap">Maintenance</button>
    </div>

    <!-- Branding Settings -->
    <div x-show="activeTab === 'branding'" x-cloak class="bg-white rounded-3xl border border-[#F0F1F5] shadow-sm overflow-hidden">
        <div class="p-8 border-b border-[#F0F1F5]">
            <h3 class="text-text-dark font-bold text-lg">Branding & Identity</h3>
            <p class="text-text-muted text-sm">Configure how the system looks and identifies itself</p>
        </div>
        <form action="{{ route('admin.settings.general') }}" method="POST" class="p-8 space-y-6">
            @csrf
            <input type="hidden" name="group" value="branding">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div class="space-y-2">
                    <label class="text-sm font-bold text-text-dark">Site Name</label>
                    <input type="text" name="site_name" value="{{ $settings['branding']['site_name'] ?? 'Lending PIS' }}" class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm">
                </div>
                <div class="space-y-2">
                    <label class="text-sm font-bold text-text-dark">Primary Theme Color</label>
                    <div class="flex gap-2">
                        <input type="color" name="theme_color" value="{{ $settings['branding']['theme_color'] ?? '#FF6F00' }}" class="h-12 w-20 bg-[#F7F8FA] border-none rounded-xl p-1">
                        <input type="text" readonly :value="$el.previousElementSibling.value" class="flex-1 bg-gray-50 border-none rounded-xl p-4 text-sm text-text-muted">
                    </div>
                </div>
            </div>
            <div class="flex justify-end">
                <button type="submit" class="bg-primary text-white font-bold px-8 py-3 rounded-xl shadow-lg">Save Branding</button>
            </div>
        </form>
    </div>

    <!-- Interest Rate (Lending Policy) -->
    <div x-show="activeTab === 'interest'" x-cloak class="bg-white rounded-3xl border border-[#F0F1F5] shadow-sm overflow-hidden">
        <div class="p-8 border-b border-[#F0F1F5] flex justify-between items-center">
            <div>
                <h3 class="text-text-dark font-bold text-lg">Standard Interest Rate</h3>
                <p class="text-text-muted text-sm">Global interest rate for new loan applications</p>
            </div>
            <div class="bg-primary/10 px-4 py-2 rounded-2xl">
                <span class="text-primary font-[800] text-xl">{{ $interestRate->rate ?? '0' }}%</span>
            </div>
        </div>
        <form action="{{ route('admin.settings.interest') }}" method="POST" class="p-8 space-y-6">
            @csrf
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div class="space-y-2">
                    <label class="text-sm font-bold text-text-dark">New Interest Rate (%)</label>
                    <input type="number" step="0.01" name="rate" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm" placeholder="e.g. 5.00">
                </div>
                <div class="space-y-2">
                    <label class="text-sm font-bold text-text-dark">Effective Date</label>
                    <input type="date" name="effective_date" value="{{ date('Y-m-d') }}" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm">
                </div>
            </div>
            <div class="flex justify-end">
                <button type="submit" class="bg-primary text-white font-bold px-8 py-3 rounded-xl shadow-lg">Update Policy</button>
            </div>
        </form>
    </div>

    <!-- Security Settings -->
    <div x-show="activeTab === 'security'" x-cloak class="bg-white rounded-3xl border border-[#F0F1F5] shadow-sm overflow-hidden">
        <div class="p-8 border-b border-[#F0F1F5]">
            <h3 class="text-text-dark font-bold text-lg">Security & Privacy</h3>
            <p class="text-text-muted text-sm">System-wide security policies and enforcement</p>
        </div>
        <form action="{{ route('admin.settings.general') }}" method="POST" class="p-8 space-y-6">
            @csrf
            <input type="hidden" name="group" value="security">
            <div class="space-y-6">
                <div class="flex items-center justify-between p-4 bg-gray-50 rounded-2xl">
                    <div>
                        <h4 class="text-sm font-bold text-text-dark">Enforce 2FA for Admins</h4>
                        <p class="text-[10px] text-text-muted">Force all administrator accounts to use Two-Factor Authentication</p>
                    </div>
                    <select name="admin_mfa_required" class="bg-white border-none rounded-lg text-xs font-bold p-2">
                        <option value="1" {{ ($settings['security']['admin_mfa_required'] ?? '') == '1' ? 'selected' : '' }}>Enabled</option>
                        <option value="0" {{ ($settings['security']['admin_mfa_required'] ?? '') == '0' ? 'selected' : '' }}>Disabled</option>
                    </select>
                </div>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div class="space-y-2">
                        <label class="text-sm font-bold text-text-dark">Session Timeout (Minutes)</label>
                        <input type="number" name="session_lifetime" value="{{ $settings['security']['session_lifetime'] ?? config('session.lifetime') }}" class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm">
                    </div>
                    <div class="space-y-2">
                        <label class="text-sm font-bold text-text-dark">Min Password Length</label>
                        <input type="number" name="min_password_length" value="{{ $settings['security']['min_password_length'] ?? 8 }}" class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm">
                    </div>
                </div>
            </div>
            <div class="flex justify-end pt-4">
                <button type="submit" class="bg-primary text-white font-bold px-8 py-3 rounded-xl shadow-lg">Save Security Policy</button>
            </div>
        </form>
    </div>

    <!-- Email Settings -->
    <div x-show="activeTab === 'email'" x-cloak class="bg-white rounded-3xl border border-[#F0F1F5] shadow-sm overflow-hidden">
        <div class="p-8 border-b border-[#F0F1F5]">
            <h3 class="text-text-dark font-bold text-lg">Email Configuration</h3>
            <p class="text-text-muted text-sm">SMTP settings for system notifications and alerts</p>
        </div>
        <form action="{{ route('admin.settings.general') }}" method="POST" class="p-8 space-y-6">
            @csrf
            <input type="hidden" name="group" value="email">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div class="space-y-2">
                    <label class="text-sm font-bold text-text-dark">SMTP Host</label>
                    <input type="text" name="mail_host" value="{{ $settings['email']['mail_host'] ?? env('MAIL_HOST') }}" class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm">
                </div>
                <div class="space-y-2">
                    <label class="text-sm font-bold text-text-dark">SMTP Port</label>
                    <input type="text" name="mail_port" value="{{ $settings['email']['mail_port'] ?? env('MAIL_PORT') }}" class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm">
                </div>
                <div class="space-y-2">
                    <label class="text-sm font-bold text-text-dark">Username</label>
                    <input type="text" name="mail_username" value="{{ $settings['email']['mail_username'] ?? env('MAIL_USERNAME') }}" class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm">
                </div>
                <div class="space-y-2">
                    <label class="text-sm font-bold text-text-dark">Encryption</label>
                    <select name="mail_encryption" class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm">
                        <option value="ssl" {{ ($settings['email']['mail_encryption'] ?? env('MAIL_ENCRYPTION')) == 'ssl' ? 'selected' : '' }}>SSL</option>
                        <option value="tls" {{ ($settings['email']['mail_encryption'] ?? env('MAIL_ENCRYPTION')) == 'tls' ? 'selected' : '' }}>TLS</option>
                    </select>
                </div>
            </div>
            <div class="flex justify-end">
                <button type="submit" class="bg-primary text-white font-bold px-8 py-3 rounded-xl shadow-lg">Save SMTP Settings</button>
            </div>
        </form>
    </div>

    <!-- Backup Settings -->
    <div x-show="activeTab === 'backup'" x-cloak class="bg-white rounded-3xl border border-[#F0F1F5] shadow-sm overflow-hidden">
        <div class="p-8 border-b border-[#F0F1F5]">
            <h3 class="text-text-dark font-bold text-lg">Backup & Data Retention</h3>
            <p class="text-text-muted text-sm">Configure automated snapshots and cleanup cycles</p>
        </div>
        <form action="{{ route('admin.settings.general') }}" method="POST" class="p-8 space-y-6">
            @csrf
            <input type="hidden" name="group" value="backup">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div class="space-y-2">
                    <label class="text-sm font-bold text-text-dark">Backup Frequency (DB)</label>
                    <select name="backup_frequency_db" class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm">
                        <option value="daily" {{ ($settings['backup']['backup_frequency_db'] ?? '') == 'daily' ? 'selected' : '' }}>Daily</option>
                        <option value="weekly" {{ ($settings['backup']['backup_frequency_db'] ?? '') == 'weekly' ? 'selected' : '' }}>Weekly</option>
                    </select>
                </div>
                <div class="space-y-2">
                    <label class="text-sm font-bold text-text-dark">Execution Time</label>
                    <input type="time" name="backup_time_db" value="{{ $settings['backup']['backup_time_db'] ?? '02:00' }}" class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm">
                </div>
                <div class="space-y-2">
                    <label class="text-sm font-bold text-text-dark">Retention Period (Days)</label>
                    <input type="number" name="backup_retention_days" value="{{ $settings['backup']['backup_retention_days'] ?? 30 }}" class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm">
                </div>
                <div class="space-y-2">
                    <label class="text-sm font-bold text-text-dark">Alert Recipient Email</label>
                    <input type="email" name="backup_email" value="{{ $settings['backup']['backup_email'] ?? env('MAIL_FROM_ADDRESS') }}" class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm">
                </div>
            </div>
            <div class="flex justify-end">
                <button type="submit" class="bg-primary text-white font-bold px-8 py-3 rounded-xl shadow-lg">Save Backup Plan</button>
            </div>
        </form>
    </div>

    <!-- Maintenance Mode -->
    <div x-show="activeTab === 'maintenance'" x-cloak class="bg-white rounded-3xl border border-[#F0F1F5] shadow-sm overflow-hidden">
        <div class="p-8 border-b border-[#F0F1F5]">
            <h3 class="text-text-dark font-bold text-lg">Maintenance Mode</h3>
            <p class="text-text-muted text-sm">Temporarily disable public access to the system for maintenance</p>
        </div>
        <form action="{{ route('admin.settings.general') }}" method="POST" class="p-8 space-y-6">
            @csrf
            <input type="hidden" name="group" value="maintenance">
            <div class="p-6 rounded-2xl border-2 border-dashed {{ ($settings['maintenance']['maintenance_mode'] ?? '0') == '1' ? 'bg-error/5 border-error/20' : 'bg-success/5 border-success/20' }}">
                <div class="flex items-center justify-between mb-6">
                    <div class="flex items-center gap-4">
                        <div class="w-12 h-12 rounded-xl flex items-center justify-center {{ ($settings['maintenance']['maintenance_mode'] ?? '0') == '1' ? 'bg-error/10 text-error' : 'bg-success/10 text-success' }}">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" /></svg>
                        </div>
                        <div>
                            <h4 class="text-sm font-bold text-text-dark">System Status: <span class="{{ ($settings['maintenance']['maintenance_mode'] ?? '0') == '1' ? 'text-error' : 'text-success' }} uppercase">{{ ($settings['maintenance']['maintenance_mode'] ?? '0') == '1' ? 'Offline' : 'Online' }}</span></h4>
                            <p class="text-[10px] text-text-muted">Admins can still access the dashboard during maintenance.</p>
                        </div>
                    </div>
                    <select name="maintenance_mode" class="bg-white border-none rounded-lg text-xs font-bold p-2 ring-1 ring-gray-200">
                        <option value="0" {{ ($settings['maintenance']['maintenance_mode'] ?? '0') == '0' ? 'selected' : '' }}>Online (Public Access)</option>
                        <option value="1" {{ ($settings['maintenance']['maintenance_mode'] ?? '0') == '1' ? 'selected' : '' }}>Offline (Maintenance)</option>
                    </select>
                </div>
                <div class="space-y-2">
                    <label class="text-[10px] font-bold text-text-muted uppercase">Maintenance Message</label>
                    <textarea name="maintenance_message" class="w-full bg-white border-none rounded-xl p-4 text-sm h-24 focus:ring-1 focus:ring-primary" placeholder="e.g. System is currently undergoing scheduled maintenance. Please try again later.">{{ $settings['maintenance']['maintenance_message'] ?? '' }}</textarea>
                </div>
            </div>
            <div class="flex justify-end">
                <button type="submit" class="bg-text-dark text-white font-bold px-8 py-3 rounded-xl shadow-lg">Apply Status</button>
            </div>
        </form>
    </div>
</div>

<style>
    .no-scrollbar::-webkit-scrollbar { display: none; }
    .no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
</style>
@endsection
