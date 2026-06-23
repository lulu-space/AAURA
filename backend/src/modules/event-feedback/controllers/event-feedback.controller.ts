import { CrudController } from '../../../shared/utils/crud-controller.js';
import { eventFeedbackService } from '../services/event-feedback.service.js';

export const eventFeedbackController = new CrudController(eventFeedbackService, 'Event feedback');

