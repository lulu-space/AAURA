import { buildCrudRouter } from '../../../shared/utils/crud-route-builder.js';
import { eventFeedbackController } from '../controllers/event-feedback.controller.js';
import { createEventFeedbackSchema, updateEventFeedbackSchema } from '../dto/event-feedback.dto.js';

export default buildCrudRouter({
  controller: eventFeedbackController,
  createSchema: createEventFeedbackSchema,
  updateSchema: updateEventFeedbackSchema
});

