import { SupabaseCrudService } from '../../../shared/utils/supabase-crud.service.js';

export const systemLogsService = new SupabaseCrudService('system_logs', '*', {
  adminOnlyRead: true,
  createRoles: ['admin'],
  writeRoles: ['admin']
});
