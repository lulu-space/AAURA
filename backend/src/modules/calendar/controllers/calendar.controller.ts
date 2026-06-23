import { CrudController } from '../../../shared/utils/crud-controller.js';
import { calendarService } from '../services/calendar.service.js';

export const calendarController = new CrudController(calendarService, 'Calendar items');
