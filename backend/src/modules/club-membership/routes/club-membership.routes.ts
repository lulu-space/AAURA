import { buildCrudRouter } from '../../../shared/utils/crud-route-builder.js';
import { clubMembershipController } from '../controllers/club-membership.controller.js';
import { createClubMembershipSchema, updateClubMembershipSchema } from '../dto/club-membership.dto.js';

export default buildCrudRouter({
  controller: clubMembershipController,
  createSchema: createClubMembershipSchema,
  updateSchema: updateClubMembershipSchema
});

