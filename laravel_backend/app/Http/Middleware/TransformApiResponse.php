<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Illuminate\Support\Str;

class TransformApiResponse
{
    /**
     * Handle an incoming request.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        if ($request->expectsJson() && $response->getStatusCode() === 200) {
            $content = json_decode($response->getContent(), true);

            if (is_array($content)) {
                // 1. Field Filtering
                if ($request->has('fields')) {
                    $fields = explode(',', $request->query('fields'));
                    $content = $this->filterFields($content, $fields);
                }

                // 2. camelCase Transformation
                $content = $this->snakeToCamel($content);

                $response->setContent(json_encode($content));
            }
        }

        return $response;
    }

    private function filterFields(array $data, array $fields)
    {
        // Simple implementation for top-level or 'data' key
        if (isset($data['data']) && is_array($data['data'])) {
            if (isset($data['data'][0])) { // Collection
                foreach ($data['data'] as &$item) {
                    $item = array_intersect_key($item, array_flip($fields));
                }
            } else { // Single resource
                $data['data'] = array_intersect_key($data['data'], array_flip($fields));
            }
        }
        return $data;
    }

    private function snakeToCamel(array $array)
    {
        $transformed = [];
        foreach ($array as $key => $value) {
            $newKey = Str::camel($key);
            if (is_array($value)) {
                $transformed[$newKey] = $this->snakeToCamel($value);
            } else {
                $transformed[$newKey] = $value;
            }
        }
        return $transformed;
    }
}
