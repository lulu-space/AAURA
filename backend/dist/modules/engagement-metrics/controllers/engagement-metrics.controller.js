import { CrudController } from '../../../shared/utils/crud-controller.js';
import { engagementMetricsService } from '../services/engagement-metrics.service.js';
export const engagementMetricsController = new CrudController(engagementMetricsService, 'Engagement metrics');
