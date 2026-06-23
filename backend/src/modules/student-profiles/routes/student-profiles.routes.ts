import { buildCrudRouter } from '../../../shared/utils/crud-route-builder.js';
import { studentProfilesController } from '../controllers/student-profiles.controller.js';
import { createStudentProfileSchema, updateStudentProfileSchema } from '../dto/student-profiles.dto.js';

export default buildCrudRouter({
  controller: studentProfilesController,
  createSchema: createStudentProfileSchema,
  updateSchema: updateStudentProfileSchema
});

