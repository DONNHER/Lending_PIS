<?php

namespace App\Traits;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Carbon\Carbon;

/**
 * Trait AdvancedDataControls
 * 
 * Provides standardized data management methods for Eloquent models, 
 * including dynamic searching, multi-column filtering, flexible sorting, 
 * and consistent pagination responses.
 * 
 * @package App\Traits
 */
trait AdvancedDataControls
{
    /**
     * Apply advanced controls (Search, Filter, Sort, Columns) to an Eloquent query.
     * 
     * @param \Illuminate\Database\Eloquent\Builder $query
     * @param \Illuminate\Http\Request $request
     * @param array $searchableColumns List of columns to include in global search.
     * @return \Illuminate\Database\Eloquent\Builder
     */
    public function scopeApplyControls(Builder $query, Request $request, array $searchableColumns = [])
    {
        // 1. Column Selection (Visibility Preference)
        // Usage: ?columns=id,name,email
        if ($request->filled('columns')) {
            $columns = explode(',', $request->columns);
            $pk = $this->getKeyName();
            if (!in_array($pk, $columns)) {
                $columns[] = $pk; // Ensure primary key is always returned
            }
            $query->select($columns);
        }

        // 2. Global Search across multiple columns
        // Usage: ?search=keyword
        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search, $searchableColumns) {
                foreach ($searchableColumns as $column) {
                    if (str_contains($column, '.')) {
                        // Support for relationship search (e.g. 'user.name')
                        [$relation, $relColumn] = explode('.', $column);
                        $q->orWhereHas($relation, function($subQuery) use ($relColumn, $search) {
                            $subQuery->where($relColumn, 'like', "%{$search}%");
                        });
                    } else {
                        $q->orWhere($column, 'like', "%{$search}%");
                    }
                }
            });
        }

        // 3. Column-specific search
        // Usage: ?search_email=john@example.com
        foreach ($searchableColumns as $column) {
            $paramName = "search_" . str_replace('.', '_', $column);
            if ($request->filled($paramName)) {
                $val = $request->get($paramName);
                if (str_contains($column, '.')) {
                    [$relation, $relColumn] = explode('.', $column);
                    $query->whereHas($relation, function($subQuery) use ($relColumn, $val) {
                        $subQuery->where($relColumn, 'like', "%{$val}%");
                    });
                } else {
                    $query->where($column, 'like', "%{$val}%");
                }
            }
        }

        // 4. Dynamic Sorting
        // Usage: ?sort_by=created_at&sort_order=desc
        $sortColumn = $request->get('sort_by', $this->getCreatedAtColumn() ?? $this->getKeyName());
        $sortDirection = $request->get('sort_order', 'desc');
        $sortDirection = in_array(strtolower($sortDirection), ['asc', 'desc']) ? $sortDirection : 'desc';
        
        $query->orderBy($sortColumn, $sortDirection);

        // 5. Standard Filters (Status, Category, Role, Date Range)
        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('category')) {
            $query->where('category', $request->category);
        }

        if ($request->filled('role')) {
            $query->where('role', $request->role);
        }

        // Date range validation (created_at by default)
        if ($request->filled('start_date')) {
            $dateColumn = $request->get('date_column', 'created_at');
            $query->whereDate($dateColumn, '>=', Carbon::parse($request->start_date));
        }
        
        if ($request->filled('end_date')) {
            $dateColumn = $request->get('date_column', 'created_at');
            $query->whereDate($dateColumn, '<=', Carbon::parse($request->end_date));
        }

        return $query;
    }

    /**
     * Standardize the paginated JSON response structure.
     * 
     * @param \Illuminate\Database\Eloquent\Builder $query
     * @param \Illuminate\Http\Request $request
     * @return array Standardized response containing 'data' and 'meta' pagination info.
     */
    public function getPaginatedResponse(Builder $query, Request $request)
    {
        $perPage = (int) $request->get('per_page', 10);
        // Valid page sizes: 10, 25, 50, 100
        if (!in_array($perPage, [10, 25, 50, 100])) {
            $perPage = 10;
        }

        $paginated = $query->paginate($perPage);

        return [
            'success' => true,
            'data' => $paginated->items(),
            'meta' => [
                'current_page' => $paginated->currentPage(),
                'last_page' => $paginated->lastPage(),
                'per_page' => $paginated->perPage(),
                'total' => $paginated->total(),
                'from' => $paginated->firstItem(),
                'to' => $paginated->lastItem(),
            ]
        ];
    }
}
