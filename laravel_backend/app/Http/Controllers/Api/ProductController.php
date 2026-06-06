<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\GroceryBatch;
use App\Models\ActivityLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Response;

/**
 * Class ProductController
 * 
 * Handles the inventory and product catalog management. 
 * Supports advanced search, soft deletes, and bulk operations.
 * 
 * @package App\Http\Controllers\Api
 */
class ProductController extends Controller
{
    /**
     * Display a listing of products with advanced controls.
     * Supports pagination, global search, and filtering by category/status.
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function index(Request $request)
    {
        $searchable = ['name', 'description', 'category', 'unit'];
        
        $query = Product::query();

        // Handle Soft Delete filters
        if ($request->boolean('trashed_only')) {
            $query->onlyTrashed();
        } elseif ($request->boolean('with_trashed')) {
            $query->withTrashed();
        }

        $query = Product::applyControls($query, $request, $searchable);

        return response()->json(Product::getPaginatedResponse($query, $request));
    }

    /**
     * Store a new product in the catalog.
     */
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'category' => 'required|string',
            'selling_price' => 'required|numeric',
            'unit' => 'required|string',
        ]);

        $product = Product::create($request->all());
        return response()->json([
            'success' => true, 
            'message' => 'Product created successfully', 
            'data' => $product
        ], 201);
    }

    /**
     * Display the specified product along with its audit trail.
     */
    public function show($id)
    {
        $product = Product::withTrashed()->findOrFail($id);
        
        // Fetch specific audit trail for this product
        $auditTrail = ActivityLog::where('description', 'like', "%products (ID: {$id})%")
            ->latest('created_at')
            ->limit(20)
            ->get();

        return response()->json([
            'success' => true, 
            'data' => $product,
            'audit_trail' => $auditTrail
        ]);
    }

    /**
     * Update product details with Optimistic Locking protection.
     */
    public function update(Request $request, $id)
    {
        $product = Product::findOrFail($id);

        $request->validate([
            'version' => 'required|integer', // Enforce versioning for concurrency control
        ]);

        try {
            $product->version = $request->version;
            $product->update($request->all());

            return response()->json([
                'success' => true, 
                'message' => 'Product updated successfully', 
                'data' => $product
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false, 
                'message' => $e->getMessage()
            ], 409); // Conflict status
        }
    }

    /**
     * Soft delete a product.
     * Checks for existing stock batches before allowing deletion.
     */
    public function destroy($id)
    {
        $product = Product::findOrFail($id);

        // Cascade delete warning: Prevent deletion if stock exists
        $hasStock = $product->batches()->where('quantity', '>', 0)->exists();
        if ($hasStock && !request()->boolean('force')) {
            return response()->json([
                'success' => false,
                'requires_confirmation' => true,
                'message' => 'This product has active stock in batches. Deleting will hide inventory. Proceed?'
            ], 409);
        }

        $product->delete();
        return response()->json(['success' => true, 'message' => 'Product soft-deleted successfully']);
    }

    /**
     * Restore a previously soft-deleted product.
     */
    public function restore($id)
    {
        $product = Product::onlyTrashed()->findOrFail($id);
        $product->restore();

        return response()->json(['success' => true, 'message' => 'Product restored successfully', 'data' => $product]);
    }

    /**
     * Perform bulk operations on multiple product records.
     * Supported actions: delete, restore, update_status, export.
     */
    public function bulkAction(Request $request)
    {
        $request->validate([
            'ids' => 'required|array',
            'action' => 'required|string|in:delete,restore,update_status,export',
            'status' => 'required_if:action,update_status'
        ]);

        $ids = $request->ids;

        switch ($request->action) {
            case 'delete':
                Product::whereIn('id', $ids)->delete();
                return response()->json(['success' => true, 'message' => count($ids) . ' products soft-deleted.']);
            
            case 'restore':
                Product::onlyTrashed()->whereIn('id', $ids)->restore();
                return response()->json(['success' => true, 'message' => count($ids) . ' products restored.']);

            case 'update_status':
                Product::whereIn('id', $ids)->update(['status' => $request->status]);
                return response()->json(['success' => true, 'message' => count($ids) . ' products updated to ' . $request->status]);
            
            case 'export':
                return $this->export($request, $ids);
        }
    }

    /**
     * Export products to a CSV file.
     */
    public function export(Request $request, $ids = null)
    {
        $query = Product::query();
        if ($ids) {
            $query->whereIn('id', $ids);
        } else {
            $query = Product::applyControls($query, $request, ['name', 'category']);
        }

        $products = $query->get();
        $csvFileName = 'products_export_' . date('Ymd_His') . '.csv';
        
        $headers = [
            "Content-type"        => "text/csv",
            "Content-Disposition" => "attachment; filename=$csvFileName",
        ];

        $callback = function() use($products) {
            $file = fopen('php://output', 'w');
            fputcsv($file, ['ID', 'Name', 'Category', 'Price', 'Unit', 'Status', 'Created At']);

            foreach ($products as $product) {
                fputcsv($file, [
                    $product->id,
                    $product->name,
                    $product->category,
                    $product->selling_price,
                    $product->unit,
                    $product->status,
                    $product->created_at,
                ]);
            }
            fclose($file);
        };

        return response()->stream($callback, 200, $headers);
    }

    /**
     * Get all stock batches for a specific product.
     */
    public function getBatches($id)
    {
        $batches = GroceryBatch::where('product_id', $id)->latest()->get();
        return response()->json(['success' => true, 'data' => $batches]);
    }
}
