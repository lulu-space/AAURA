import { CrudController } from '../../../shared/utils/crud-controller.js';
import { searchHistoryService } from '../services/search-history.service.js';

export const searchHistoryController = new CrudController(searchHistoryService, 'Search history');

