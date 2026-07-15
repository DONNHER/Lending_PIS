<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>{{ $title ?? 'Report' }}</title>
    <style>
        @page {
            margin: 18mm 16mm 22mm 16mm;
        }

        body {
            font-family: DejaVu Sans, Arial, sans-serif;
            color: #111827;
            font-size: 10pt;
            line-height: 1.45;
        }

        .header {
            border-bottom: 2px solid #c06c4d;
            padding-bottom: 10px;
            margin-bottom: 14px;
        }

        .brand {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 6px;
        }

        .brand-box {
            background: #1f2937;
            color: white;
            padding: 8px 12px;
            border-radius: 8px;
            font-weight: bold;
            letter-spacing: 0.04em;
        }

        .meta {
            color: #6b7280;
            font-size: 9pt;
        }

        .card {
            border: 1px solid #e5e7eb;
            border-radius: 8px;
            padding: 12px;
            margin-bottom: 14px;
            background: #f9fafb;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 8px;
        }

        th, td {
            border: 1px solid #e5e7eb;
            padding: 8px;
            text-align: left;
            vertical-align: top;
        }

        th {
            background: #f3f4f6;
            font-weight: 700;
        }

        .summary {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            margin-bottom: 12px;
        }

        .summary-item {
            border: 1px solid #e5e7eb;
            border-radius: 8px;
            background: #fff;
            padding: 8px 10px;
            min-width: 120px;
        }

        .footer {
            position: fixed;
            bottom: 10mm;
            left: 0;
            right: 0;
            font-size: 8pt;
            color: #6b7280;
            border-top: 1px solid #e5e7eb;
            padding-top: 6px;
            text-align: center;
        }

        @media print {
            body {
                font-size: 9pt;
            }

            .card {
                box-shadow: none;
            }
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="brand">
            <div class="brand-box">CAPSTONE LENDING SYSTEM</div>
            <div>{{ $title ?? 'Report' }}</div>
        </div>
        <div class="meta">
            Generated on {{ $generatedAt ?? now()->toDateTimeString() }} · {{ $subtitle ?? 'Business report' }}
        </div>
    </div>

    @if(!empty($summary))
        <div class="summary">
            @foreach($summary as $item)
                <div class="summary-item">
                    <strong>{{ $item['label'] ?? '' }}</strong><br>
                    {{ $item['value'] ?? '' }}
                </div>
            @endforeach
        </div>
    @endif

    @if(!empty($filters))
        <div class="card">
            <strong>Filters applied</strong>
            <div>{{ json_encode($filters) }}</div>
        </div>
    @endif

    @if(!empty($rows))
        <table>
            <thead>
                <tr>
                    @foreach($headers as $header)
                        <th>{{ $header }}</th>
                    @endforeach
                </tr>
            </thead>
            <tbody>
                @foreach($rows as $row)
                    <tr>
                        @foreach($row as $value)
                            <td>{{ $value }}</td>
                        @endforeach
                    </tr>
                @endforeach
            </tbody>
        </table>
    @else
        <div class="card">No data available for this report.</div>
    @endif

    <div class="footer">
        Confidential business report · Printed by Capstone Lending System
    </div>
</body>
</html>
