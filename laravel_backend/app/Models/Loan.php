<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\SoftDeletes;
use App\Traits\Loggable;
use App\Traits\AdvancedDataControls;
use App\Traits\Versionable;

/**
 * Class Loan
 * 
 * Represents an approved loan disbursed to a shareholder.
 * Tracks the principal, interest, repayment terms, and current balance.
 * 
 * @package App\Models
 */
class Loan extends Model
{
    use HasFactory, HasUuids, Loggable, AdvancedDataControls, SoftDeletes, Versionable;

    protected $fillable = [
        'shareholder_id',
        'loan_request_id',
        'principal_amount',
        'interest_rate',
        'term_months',
        'monthly_installment',
        'total_payable',
        'remaining_balance',
        'status',
        'due_date',
        'disbursed_at',
        'version',
    ];

    protected $casts = [
        'principal_amount' => 'decimal:2',
        'interest_rate' => 'decimal:2',
        'monthly_installment' => 'decimal:2',
        'total_payable' => 'decimal:2',
        'remaining_balance' => 'decimal:2',
        'due_date' => 'date',
        'disbursed_at' => 'datetime',
        'version' => 'integer',
    ];

    /**
     * Relationship: The shareholder who owns this loan.
     */
    public function shareholder()
    {
        return $this->belongsTo(Shareholder::class);
    }
}
