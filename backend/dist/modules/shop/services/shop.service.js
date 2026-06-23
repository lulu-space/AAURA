import { ApiError } from '../../../core/errors/api-error.js';
import { supabaseAdmin } from '../../../config/supabase.js';
export class ShopItemsService {
    async listActive() {
        const { data, error } = await supabaseAdmin
            .from('shop_items')
            .select('*')
            .eq('is_active', true)
            .order('cost', { ascending: true });
        if (error)
            throw new ApiError(500, 'Failed to fetch shop items.', error);
        return data;
    }
}
export class ShopWorkflowService {
    async listPurchases(userId) {
        const { data, error } = await supabaseAdmin
            .from('shop_purchases')
            .select('*, shop_items(*)')
            .eq('user_id', userId)
            .order('purchased_at', { ascending: false });
        if (error)
            throw new ApiError(500, 'Failed to fetch purchases.', error);
        return data;
    }
    async purchase(itemId, userId) {
        const { data: item, error: itemError } = await supabaseAdmin
            .from('shop_items')
            .select('*')
            .eq('id', itemId)
            .eq('is_active', true)
            .single();
        if (itemError || !item) {
            throw new ApiError(404, 'Shop item not found.', itemError);
        }
        const { data: existingPurchase } = await supabaseAdmin
            .from('shop_purchases')
            .select('id')
            .eq('user_id', userId)
            .eq('shop_item_id', itemId)
            .maybeSingle();
        if (existingPurchase) {
            throw new ApiError(409, 'You already own this item.');
        }
        const { data: gamification, error: gamError } = await supabaseAdmin
            .from('gamification')
            .select('id, points')
            .eq('user_id', userId)
            .single();
        if (gamError || !gamification) {
            throw new ApiError(404, 'Gamification profile not found.', gamError);
        }
        if (gamification.points < item.cost) {
            throw new ApiError(400, 'Not enough points.');
        }
        const nextPoints = gamification.points - item.cost;
        const { error: pointsError } = await supabaseAdmin
            .from('gamification')
            .update({ points: nextPoints })
            .eq('id', gamification.id);
        if (pointsError) {
            throw new ApiError(500, 'Failed to deduct points.', pointsError);
        }
        const { data: purchase, error: purchaseError } = await supabaseAdmin
            .from('shop_purchases')
            .insert({
            user_id: userId,
            shop_item_id: itemId,
            points_spent: item.cost
        })
            .select('*, shop_items(*)')
            .single();
        if (purchaseError) {
            await supabaseAdmin
                .from('gamification')
                .update({ points: gamification.points })
                .eq('id', gamification.id);
            throw new ApiError(500, 'Failed to record purchase.', purchaseError);
        }
        return {
            purchase,
            points: nextPoints,
            gamification_id: gamification.id
        };
    }
}
export const shopItemsService = new ShopItemsService();
export const shopWorkflowService = new ShopWorkflowService();
