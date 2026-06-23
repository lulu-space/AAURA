import { buildCrudRouter } from '../../../shared/utils/crud-route-builder.js';
import { systemLogsController } from '../controllers/system-logs.controller.js';
import {
  createSystemLogSchema,
  updateSystemLogSchema
} from '../dto/system-logs.dto.js';

export default buildCrudRouter({
  controller: systemLogsController,
  createSchema: createSystemLogSchema,
  updateSchema: updateSystemLogSchema
});
