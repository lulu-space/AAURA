import { CrudController } from '../../../shared/utils/crud-controller.js';
import { studySessionsService } from '../services/study-sessions.service.js';

export const studySessionsController = new CrudController(studySessionsService, 'Study sessions');
