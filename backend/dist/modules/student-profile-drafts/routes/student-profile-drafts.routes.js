import { buildCrudRouter } from '../../../shared/utils/crud-route-builder.js';
import { studentProfileDraftsController } from '../controllers/student-profile-drafts.controller.js';
import { createStudentProfileDraftSchema, updateStudentProfileDraftSchema } from '../dto/student-profile-drafts.dto.js';
export default buildCrudRouter({
    controller: studentProfileDraftsController,
    createSchema: createStudentProfileDraftSchema,
    updateSchema: updateStudentProfileDraftSchema
});
