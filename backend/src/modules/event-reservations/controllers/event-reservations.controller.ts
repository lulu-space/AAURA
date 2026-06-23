import { CrudController } from '../../../shared/utils/crud-controller.js';
import { eventReservationsService } from '../services/event-reservations.service.js';

export const eventReservationsController = new CrudController(
  eventReservationsService,
  'Event reservations'
);

