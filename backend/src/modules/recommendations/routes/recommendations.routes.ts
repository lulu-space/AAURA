import { buildCrudRouter } from '../../../shared/utils/crud-route-builder.js';
import { recommendationsController } from '../controllers/recommendations.controller.js';
import {
  createRecommendationSchema,
  updateRecommendationSchema
} from '../dto/recommendations.dto.js';

export default buildCrudRouter({
  controller: recommendationsController,
  createSchema: createRecommendationSchema,
  updateSchema: updateRecommendationSchema
});
