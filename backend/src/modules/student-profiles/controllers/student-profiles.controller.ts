import { CrudController } from '../../../shared/utils/crud-controller.js';
import { studentProfilesService } from '../services/student-profiles.service.js';

export const studentProfilesController = new CrudController(studentProfilesService, 'Student profiles');

