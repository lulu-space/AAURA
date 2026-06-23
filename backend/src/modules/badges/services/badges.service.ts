import { ApiError } from '../../../core/errors/api-error.js';
import { supabaseAdmin } from '../../../config/supabase.js';

export class BadgesService {
  async listDefinitions() {
    const { data, error } = await supabaseAdmin
      .from('badge_definitions')
      .select('*')
      .order('sort_order', { ascending: true });

    if (error) throw new ApiError(500, 'Failed to fetch badge catalog.', error);
    return data;
  }
}

export const badgesService = new BadgesService();
