import { CrudController } from '../../../shared/utils/crud-controller.js';
import { recommendationsService } from '../services/recommendations.service.js';

export const recommendationsController = new CrudController(
  recommendationsService,
  'Recommendations'
);
