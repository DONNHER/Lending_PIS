private function updateSupabasePassword($email, $newPassword)
    {
        try {
            // 🔑 Read directly from environment variables (your .env file)
            $supabaseUrl = env('SUPABASE_URL');
            $serviceRoleKey = env('SUPABASE_SERVICE_ROLE_KEY');

            if (!$supabaseUrl || !$serviceRoleKey) {
                Log::warning('Supabase environment variables (SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY) are missing. Skipping remote sync.');
                return false;
            }

            // 1. Find Supabase User ID by Email
            $searchResponse = Http::withHeaders([
                'apikey' => $serviceRoleKey,
                'Authorization' => 'Bearer ' . $serviceRoleKey,
            ])->get("{$supabaseUrl}/auth/v1/admin/users");

            if (!$searchResponse->successful()) {
                Log::error('Failed to fetch users from Supabase Admin API', ['response' => $searchResponse->body()]);
                return false;
            }

            $users = $searchResponse->json('users') ?? [];
            $supabaseUserId = null;
            foreach ($users as $u) {
                if ($u['email'] === $email) {
                    $supabaseUserId = $u['id'];
                    break;
                }
            }

            if (!$supabaseUserId) {
                Log::warning('User not found in Supabase Auth during password sync', ['email' => $email]);
                return false;
            }

            // 2. Update password via Supabase Admin API
            $updateResponse = Http::withHeaders([
                'apikey' => $serviceRoleKey,
                'Authorization' => 'Bearer ' . $serviceRoleKey,
                'Content-Type' => 'application/json',
            ])->put("{$supabaseUrl}/auth/v1/admin/users/{$supabaseUserId}", [
                'password' => $newPassword
            ]);

            if (!$updateResponse->successful()) {
                Log::error('Failed to update Supabase password via Admin API', ['response' => $updateResponse->body()]);
                return false;
            }

            return true;
        } catch (\Exception $e) {
            Log::error('Exception during Supabase password sync: ' . $e->getMessage());
            return false;
        }
    }