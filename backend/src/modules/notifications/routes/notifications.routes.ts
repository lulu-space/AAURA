import { buildCrudRouter } from '../../../shared/utils/crud-route-builder.js';
import { notificationsController } from '../controllers/notifications.controller.js';
import {
  createNotificationSchema,
  updateNotificationSchema
} from '../dto/notifications.dto.js';

export default buildCrudRouter({
  controller: notificationsController,
  createSchema: createNotificationSchema,
  updateSchema: updateNotificationSchema
});
