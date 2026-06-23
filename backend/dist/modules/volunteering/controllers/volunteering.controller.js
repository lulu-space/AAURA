import { CrudController } from '../../../shared/utils/crud-controller.js';
import { volunteeringService } from '../services/volunteering.service.js';
export const volunteeringController = new CrudController(volunteeringService, 'Volunteering records');
