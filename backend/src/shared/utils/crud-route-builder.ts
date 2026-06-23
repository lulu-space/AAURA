import { Router } from 'express';
import { z } from 'zod';
import { asyncHandler } from '../middleware/async-handler.js';
import { validateRequest } from '../middleware/validation/validate-request.js';

const idParamsSchema = {
  params: z.object({ id: z.string().uuid() }),
  body: z.object({}).default({}),
  query: z.object({}).default({})
};

export const buildCrudRouter = ({
  controller,
  createSchema,
  updateSchema
}: {
  controller: {
    list: Function;
    getById: Function;
    create: Function;
    update: Function;
    remove: Function;
  };
  createSchema: z.ZodTypeAny;
  updateSchema: z.ZodTypeAny;
}) => {
  const router = Router();

  router.get('/', asyncHandler((req, res) => controller.list(req, res)));
  router.get('/:id', validateRequest(z.object(idParamsSchema)), asyncHandler((req, res) => controller.getById(req, res)));
  router.post('/', validateRequest(createSchema), asyncHandler((req, res) => controller.create(req, res)));
  router.patch('/:id', validateRequest(updateSchema), asyncHandler((req, res) => controller.update(req, res)));
  router.delete('/:id', validateRequest(z.object(idParamsSchema)), asyncHandler((req, res) => controller.remove(req, res)));

  return router;
};
