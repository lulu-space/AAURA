import { CrudController } from '../../../shared/utils/crud-controller.js';
import { clubMembershipService } from '../services/club-membership.service.js';

export const clubMembershipController = new CrudController(clubMembershipService, 'Club membership');

