<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Consignee;
use App\Models\Consignment;
use App\Models\Product;
use Illuminate\Http\Request;

class ConsignmentController extends Controller
{
    public function index()
    {
        $consignees = Consignee::latest()->paginate(10);
        return view('admin.consignments.index', compact('consignees'));
    }

    public function products()
    {
        $products = Product::with('consignee')->latest()->paginate(15);
        return view('admin.consignments.products', compact('products'));
    }

    public function showConsignee(Consignee $consignee)
    {
        $consignee->load('products');
        return view('admin.consignments.consignee_detail', compact('consignee'));
    }
}
