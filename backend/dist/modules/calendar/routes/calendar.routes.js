import { buildCrudRouter } from '../../../shared/utils/crud-route-builder.js';
import { calendarController } from '../controllers/calendar.controller.js';
import { createCalendarSchema, updateCalendarSchema } from '../dto/calendar.dto.js';
export default buildCrudRouter({
    controller: calendarController,
    createSchema: createCalendarSchema,
    updateSchema: updateCalendarSchema
});
