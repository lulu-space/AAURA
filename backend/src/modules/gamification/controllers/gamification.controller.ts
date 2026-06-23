import { CrudController } from '../../../shared/utils/crud-controller.js';
import { gamificationService } from '../services/gamification.service.js';

export const gamificationController = new CrudController(gamificationService, 'Gamification');
