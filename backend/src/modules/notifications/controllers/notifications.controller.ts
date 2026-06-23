import { CrudController } from '../../../shared/utils/crud-controller.js';
import { notificationsService } from '../services/notifications.service.js';

export const notificationsController = new CrudController(notificationsService, 'Notifications');
