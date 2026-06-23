import { buildCrudRouter } from '../../../shared/utils/crud-route-builder.js';
import { studentsController } from '../controllers/students.controller.js';
import { createStudentSchema, updateStudentSchema } from '../dto/students.dto.js';

export default buildCrudRouter({
  controller: studentsController,
  createSchema: createStudentSchema,
  updateSchema: updateStudentSchema
});

