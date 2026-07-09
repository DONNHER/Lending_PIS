<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index()
    {
        $notifications = Notification::where('user_id', auth()->id())
            ->latest('created_at')
            ->paginate(15);

        return view('notifications.index', compact('notifications'));
    }

    public function markAsRead(Notification $notification)
    {
        if ($notification->user_id !== auth()->id()) {
            abort(403);
        }

        $notification->update(['is_unread' => false]);
        return back();
    }

    public function markAllAsRead()
    {
        Notification::where('user_id', auth()->id())->update(['is_unread' => false]);
        return back()->with('success', 'All notifications marked as read.');
    }
}
