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
 */
class Transaction extends Model
{
    use Loggable, AdvancedDataControls, SoftDeletes, Versionable;

    protected $keyType = 'int';
    public $incrementing = true;
    public $timestamps = false;

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
     * Relationship: The shareholder associated with this transaction.
     */
    public function shareholder()
    {
        return $this->belongsTo(Shareholder::class);
    }
}
