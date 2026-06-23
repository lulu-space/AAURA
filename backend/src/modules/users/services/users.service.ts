import { ApiError } from '../../../core/errors/api-error.js';
import { supabaseAdmin } from '../../../config/supabase.js';

export class UsersService {
  async getMe(userId: string) {
    const { data, error } = await supabaseAdmin
      .from('users')
      .select('*, students(*), student_profiles(*)')
      .eq('id', userId)
      .single();

    if (error) throw new ApiError(404, 'User not found.', error);
    return data;
  }

  async updateMe(userId: string, payload: Record<string, unknown>, role?: string) {
    if (payload.assigned_faculty != null && role !== 'dean_of_faculty') {
      throw new ApiError(403, 'Only deans can set assigned faculty.');
    }

    const { data, error } = await supabaseAdmin
      .from('users')
      .update(payload)
      .eq('id', userId)
      .select('*')
      .single();

    if (error) throw new ApiError(500, 'Failed to update user.', error);
    return data;
  }

  async adminList() {
    const { data, error } = await supabaseAdmin.from('users').select('*').order('created_at', {
      ascending: false
    });
    if (error) throw new ApiError(500, 'Failed to fetch users.', error);
    return data;
  }

  async adminGetById(id: string) {
    const { data, error } = await supabaseAdmin.from('users').select('*').eq('id', id).single();
    if (error) throw new ApiError(404, 'User not found.', error);
    return data;
  }

  async adminUpdate(id: string, payload: Record<string, unknown>) {
    const { data, error } = await supabaseAdmin
      .from('users')
      .update(payload)
      .eq('id', id)
      .select('*')
      .single();

    if (error) throw new ApiError(500, 'Failed to update user.', error);
    return data;
  }
}

export const usersService = new UsersService();

