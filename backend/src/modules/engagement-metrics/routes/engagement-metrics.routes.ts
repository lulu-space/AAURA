import { buildCrudRouter } from '../../../shared/utils/crud-route-builder.js';
import { engagementMetricsController } from '../controllers/engagement-metrics.controller.js';
import { createEngagementMetricSchema, updateEngagementMetricSchema } from '../dto/engagement-metrics.dto.js';

export default buildCrudRouter({
  controller: engagementMetricsController,
  createSchema: createEngagementMetricSchema,
  updateSchema: updateEngagementMetricSchema
});

