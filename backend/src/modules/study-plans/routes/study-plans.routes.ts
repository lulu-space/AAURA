import { buildCrudRouter } from '../../../shared/utils/crud-route-builder.js';
import { studyPlansController } from '../controllers/study-plans.controller.js';
import { createStudyPlanSchema, updateStudyPlanSchema } from '../dto/study-plans.dto.js';

export default buildCrudRouter({
  controller: studyPlansController,
  createSchema: createStudyPlanSchema,
  updateSchema: updateStudyPlanSchema
});

