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
 * Class Product
 * 
 * Represents an item in the inventory catalog.
 * Supports stock tracking via batches and soft-deletion for data integrity.
 * 
 * @package App\Models
 */
class Product extends Model
{
    use HasFactory, HasUuids, Loggable, AdvancedDataControls, SoftDeletes, Versionable;

    protected $fillable = [
        'name',
        'description',
        'category',
        'unit',
        'selling_price',
        'status',
        'version',
    ];

    protected $casts = [
        'selling_price' => 'decimal:2',
        'version' => 'integer',
    ];

    /**
     * Relationship: Inventory batches associated with this product.
     */
    public function batches()
    {
        return $this->hasMany(GroceryBatch::class);
    }
}
