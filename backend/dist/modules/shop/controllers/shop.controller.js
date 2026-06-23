import { shopItemsService, shopWorkflowService } from '../services/shop.service.js';
export class ShopController {
    async listItems(_req, res) {
        const data = await shopItemsService.listActive();
        res.json({ message: 'Shop items fetched.', data });
    }
    async listPurchases(req, res) {
        const data = await shopWorkflowService.listPurchases(req.authUser.id);
        res.json({ message: 'Purchases fetched.', data });
    }
    async purchase(req, res) {
        const { item_id } = req.body;
        const data = await shopWorkflowService.purchase(item_id, req.authUser.id);
        res.status(201).json({ message: 'Purchase completed.', data });
    }
}
export const shopController = new ShopController();
