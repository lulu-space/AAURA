import { Router } from 'express';
import { buildCrudRouter } from '../../../shared/utils/crud-route-builder.js';
import { asyncHandler } from '../../../shared/middleware/async-handler.js';
import { validateRequest } from '../../../shared/middleware/validation/validate-request.js';
import { eventReservationsController } from '../controllers/event-reservations.controller.js';
import { eventReservationsWorkflowController } from '../controllers/event-reservations-workflow.controller.js';
import { createEventReservationSchema, updateEventReservationSchema } from '../dto/event-reservations.dto.js';
import { checkInSchema, listEventAttendeesSchema, reserveEventSchema } from '../dto/event-reservations-workflow.dto.js';
const router = Router();
router.post('/reserve', validateRequest(reserveEventSchema), asyncHandler((req, res) => eventReservationsWorkflowController.reserve(req, res)));
router.post('/check-in', validateRequest(checkInSchema), asyncHandler((req, res) => eventReservationsWorkflowController.checkIn(req, res)));
router.get('/mine', asyncHandler((req, res) => eventReservationsWorkflowController.listMine(req, res)));
router.get('/event/:eventId/attendees', validateRequest(listEventAttendeesSchema), asyncHandler((req, res) => eventReservationsWorkflowController.listAttendees(req, res)));
const crud = buildCrudRouter({
    controller: eventReservationsController,
    createSchema: createEventReservationSchema,
    updateSchema: updateEventReservationSchema
});
router.use(crud);
export default router;
