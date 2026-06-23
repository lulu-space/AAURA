import { CrudController } from '../../../shared/utils/crud-controller.js';
import { studentsService } from '../services/students.service.js';

export const studentsController = new CrudController(studentsService, 'Students');

