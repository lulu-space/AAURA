import { CrudController } from '../../../shared/utils/crud-controller.js';
import { volunteeringOpportunitiesService } from '../services/volunteering-opportunities.service.js';
export const volunteeringOpportunitiesController = new CrudController(volunteeringOpportunitiesService, 'Volunteering opportunities');
