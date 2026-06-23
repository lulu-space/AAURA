import { CrudController } from '../../../shared/utils/crud-controller.js';
import { clubsService } from '../services/clubs.service.js';
export const clubsController = new CrudController(clubsService, 'Clubs');
