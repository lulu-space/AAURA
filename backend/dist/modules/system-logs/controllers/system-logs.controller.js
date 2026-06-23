import { CrudController } from '../../../shared/utils/crud-controller.js';
import { systemLogsService } from '../services/system-logs.service.js';
export const systemLogsController = new CrudController(systemLogsService, 'System logs');
