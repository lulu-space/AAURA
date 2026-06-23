import { buildCrudRouter } from '../../../shared/utils/crud-route-builder.js';
import { searchHistoryController } from '../controllers/search-history.controller.js';
import { createSearchHistorySchema, updateSearchHistorySchema } from '../dto/search-history.dto.js';

export default buildCrudRouter({
  controller: searchHistoryController,
  createSchema: createSearchHistorySchema,
  updateSchema: updateSearchHistorySchema
});

