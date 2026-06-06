<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use App\Traits\Loggable;
use App\Traits\AdvancedDataControls;
use App\Traits\Versionable;

/**
 * Class Transaction
 * 
 * Represents a financial movement in the system ledger.
 * Tracks capital contributions, loan disbursements, and repayments.
 * 
 * @package App\Models
 */
class Transaction extends Model
{
    use Loggable, AdvancedDataControls, SoftDeletes, Versionable;

    /**
     * @var string The primary key type. Use 'int' for BigInt primary keys.
     */
    protected $keyType = 'int';
    
    /**
     * @var bool Indicates if the IDs are auto-incrementing.
     */
    public $incrementing = true;

    protected $fillable = [
        'reference_id',
        'shareholder_id',
        'type',
        'method',
        'amount',
        'status',
        'date',
        'version',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'version' => 'integer',
        'date' => 'datetime',
    ];

    /**
     * @var bool Transactions handle 'date' via DB defaults, not standard Eloquent timestamps.
     */
    public $timestamps = false;

    /**
     * Relationship: The shareholder associated with this transaction.
     */
    public function shareholder()
    {
        return $this->belongsTo(Shareholder::class);
    }
}
