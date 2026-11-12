export type Role = 'owner' | 'teacher' | 'student';
export type Profile = { id: string; email: string; full_name: string; role: Role; avatar_url: string | null; created_at: string };
export type DashboardStats = { students: number; teachers: number; classes: number; assignments: number; submissions: number; lobbies: number };
