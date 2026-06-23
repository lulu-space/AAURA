import { Router } from 'express';
import { z } from 'zod';
import { asyncHandler } from '../../../shared/middleware/async-handler.js';
import { validateRequest } from '../../../shared/middleware/validation/validate-request.js';
import { authorizeCapability } from '../../../shared/middleware/role-based/authorize-capability.js';
import { VOLUNTEERING_OPPORTUNITY_CREATOR_ROLES } from '../../../shared/constants/roles.js';
import { volunteeringOpportunitiesController } from '../controllers/volunteering-opportunities.controller.js';
import { volunteeringOpportunitiesService } from '../services/volunteering-opportunities.service.js';
import {
  createVolunteeringOpportunitySchema,
  updateVolunteeringOpportunitySchema
} from '../dto/volunteering-opportunities.dto.js';

const router = Router();
const idParamsSchema = {
  params: z.object({ id: z.string().uuid() }),
  body: z.object({}).default({}),
  query: z.object({}).default({})
};

router.get('/', asyncHandler((req, res) => volunteeringOpportunitiesController.list(req, res)));
router.post(
  '/join',
  validateRequest(
    z.object({
      params: z.object({}).default({}),
      query: z.object({}).default({}),
      body: z.object({ join_token: z.string().uuid() })
    })
  ),
  asyncHandler(async (req, res) => {
    const data = await volunteeringOpportunitiesService.applyByJoinToken(
      req.body.join_token as string,
      req.authUser!.id,
      req.authUser!.role
    );
    res.json({ message: 'Volunteer application submitted.', data });
  })
);
router.get(
  '/join/:token',
  validateRequest(
    z.object({
      params: z.object({ token: z.string().uuid() }),
      body: z.object({}).default({}),
      query: z.object({}).default({})
    })
  ),
  asyncHandler(async (req, res) => {
    const data = await volunteeringOpportunitiesService.findByJoinToken(
      req.params.token as string
    );
    res.json({ message: 'Volunteer opportunity fetched.', data });
  })
);
router.get(
  '/:id',
  validateRequest(z.object(idParamsSchema)),
  asyncHandler((req, res) => volunteeringOpportunitiesController.getById(req, res))
);
router.post(
  '/',
  authorizeCapability(VOLUNTEERING_OPPORTUNITY_CREATOR_ROLES),
  validateRequest(createVolunteeringOpportunitySchema),
  asyncHandler((req, res) => volunteeringOpportunitiesController.create(req, res))
);
router.patch(
  '/:id',
  authorizeCapability(VOLUNTEERING_OPPORTUNITY_CREATOR_ROLES),
  validateRequest(updateVolunteeringOpportunitySchema),
  asyncHandler((req, res) => volunteeringOpportunitiesController.update(req, res))
);
router.delete(
  '/:id',
  authorizeCapability(VOLUNTEERING_OPPORTUNITY_CREATOR_ROLES),
  validateRequest(z.object(idParamsSchema)),
  asyncHandler((req, res) => volunteeringOpportunitiesController.remove(req, res))
);

export default router;
