import { CrudController } from '../../../shared/utils/crud-controller.js';
import { studySessionMembershipService } from '../services/study-session-membership.service.js';

export const studySessionMembershipController = new CrudController(
  studySessionMembershipService,
  'Study session membership'
);
