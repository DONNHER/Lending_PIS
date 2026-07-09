<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title', 'System Report') - {{ date('Y-m-d') }}</title>
    <style>
        @page {
            margin: 1.5cm;
            @bottom-center {
                content: "Page " counter(page) " of " counter(pages);
            }
        }
        body {
            font-family: 'Helvetica', 'Arial', sans-serif;
            color: #333;
            line-height: 1.5;
            margin: 0;
            padding: 0;
        }
        .print-container { padding: 20px; }
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 3px solid #FF6F00;
            padding-bottom: 20px;
            margin-bottom: 30px;
        }
        .logo-section { display: flex; align-items: center; gap: 15px; }
        .logo-icon {
            width: 50px;
            height: 50px;
            background: #FF6F00;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
        }
        .brand-name { font-size: 24px; font-weight: 800; color: #FF6F00; margin: 0; }
        .report-info { text-align: right; }
        .report-info h2 { margin: 0; font-size: 18px; color: #212121; text-transform: uppercase; }
        .report-info p { margin: 2px 0; font-size: 10px; color: #757575; font-weight: bold; }

        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th {
            background: #F7F8FA;
            color: #757575;
            text-align: left;
            padding: 12px 10px;
            border: 1px solid #EEEEEE;
            font-size: 10px;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }
        td {
            padding: 12px 10px;
            border: 1px solid #EEEEEE;
            font-size: 11px;
            color: #212121;
        }
        .status-badge {
            padding: 2px 8px;
            border-radius: 4px;
            font-size: 9px;
            font-weight: bold;
            text-transform: uppercase;
            background: #F3F4F6;
        }

        .footer {
            margin-top: 50px;
            border-top: 1px solid #EEEEEE;
            padding-top: 20px;
            display: flex;
            justify-content: space-between;
            font-size: 9px;
            color: #757575;
        }
        .signature-line {
            margin-top: 40px;
            border-top: 1px solid #333;
            width: 200px;
            text-align: center;
            padding-top: 5px;
            font-weight: bold;
        }

        .no-print {
            position: fixed;
            top: 20px;
            right: 20px;
            display: flex;
            gap: 10px;
            z-index: 1000;
        }
        .btn {
            padding: 10px 20px;
            border-radius: 8px;
            font-weight: bold;
            font-size: 12px;
            cursor: pointer;
            border: none;
            transition: all 0.2s;
            text-decoration: none;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .btn-primary { background: #FF6F00; color: white; }
        .btn-secondary { background: #F3F4F6; color: #4B5563; }

        @media print {
            .no-print { display: none !important; }
            .print-container { padding: 0; }
            body { -webkit-print-color-adjust: exact; }
        }
    </style>
</head>
<body>
    <div class="no-print">
        <button onclick="window.print()" class="btn btn-primary">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 6 2 18 2 18 9"></polyline><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"></path><rect x="6" y="14" width="12" height="8"></rect></svg>
            Print to PDF
        </button>
        <button onclick="window.close()" class="btn btn-secondary">Close</button>
    </div>

    <div class="print-container">
        <div class="header">
            <div class="logo-section">
                <div class="logo-icon">
                    <svg xmlns="http://www.w3.org/2000/svg" width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M19 21V5a2 2 0 0 0-2-2H7a2 2 0 0 0-2 2v16"></path><path d="M12 11h.01"></path><path d="M12 7h.01"></path><path d="M12 15h.01"></path><path d="M16 11h.01"></path><path d="M16 7h.01"></path><path d="M16 15h.01"></path><path d="M8 11h.01"></path><path d="M8 7h.01"></path><path d="M8 15h.01"></path></svg>
                </div>
                <div>
                    <h1 class="brand-name">Lending PIS</h1>
                    <p style="margin: 0; font-size: 10px; color: #757575; font-weight: bold; text-transform: uppercase; letter-spacing: 0.1em;">Management Information System</p>
                </div>
            </div>
            <div class="report-info">
                <h2>@yield('report_title', 'System Report')</h2>
                <p>GEN DATE: {{ date('F d, Y') }}</p>
                <p>REF ID: #{{ strtoupper(substr(md5(now()), 0, 8)) }}</p>
            </div>
        </div>

        @yield('content')

        <div class="footer">
            <div>
                <p>This is a computer-generated document. No signature is required for validity unless specified.</p>
                <p>© {{ date('Y') }} Lending PIS - Management System</p>
            </div>
            <div style="text-align: right">
                <p>Generated by: {{ auth()->user()->full_name }}</p>
                <p>Source IP: {{ request()->ip() }}</p>
                <div class="signature-line">Authorized Signatory</div>
            </div>
        </div>
    </div>
</body>
</html>
