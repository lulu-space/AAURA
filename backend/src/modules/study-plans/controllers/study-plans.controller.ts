import { CrudController } from '../../../shared/utils/crud-controller.js';
import { studyPlansService } from '../services/study-plans.service.js';

export const studyPlansController = new CrudController(studyPlansService, 'Study plans');

