import { CrudController } from '../../../shared/utils/crud-controller.js';
import { studentProfileDraftsService } from '../services/student-profile-drafts.service.js';

export const studentProfileDraftsController = new CrudController(
  studentProfileDraftsService,
  'Student profile drafts'
);

