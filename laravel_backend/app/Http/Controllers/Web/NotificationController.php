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

    public function destroy(Notification $notification)
    {
        if ($notification->user_id !== auth()->id()) {
            abort(403);
        }

        $notification->delete();
        return back()->with('success', 'Notification deleted.');
    }

    /**
     * SSE stream for real-time notification count
     */
    public function stream()
    {
        return response()->stream(function () {
            while (true) {
                if (connection_aborted()) break;

                $count = Notification::where('user_id', auth()->id())
                    ->where('is_unread', true)
                    ->count();

                echo "data: " . json_encode(['unread_count' => $count]) . "\n\n";
                ob_flush();
                flush();

                sleep(5); // Update every 5 seconds
            }
        }, [
            'Content-Type' => 'text/event-stream',
            'Cache-Control' => 'no-cache',
            'Connection' => 'keep-alive',
        ]);
    }
}
