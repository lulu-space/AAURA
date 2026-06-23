import { ApiError } from '../../core/errors/api-error.js';
import { supabaseAdmin } from '../../config/supabase.js';
import type { CrudCreateDto, CrudOwnershipConfig, CrudUpdateDto } from '../interfaces/crud.types.js';

export class SupabaseCrudService {
  constructor(
    private readonly tableName: string,
    private readonly selectClause = '*',
    private readonly ownership: CrudOwnershipConfig = {}
  ) {}

  private async assertCanMutate(id: string, userId: string, role?: string) {
    if (role === 'admin') return;

    if (this.ownership.ownerColumn) {
      const { data, error } = await supabaseAdmin
        .from(this.tableName)
        .select(`id, ${this.ownership.ownerColumn}`)
        .eq('id', id)
        .single();

      if (error || !data) {
        throw new ApiError(404, `${this.tableName} record not found.`, error);
      }

      const ownerCol = this.ownership.ownerColumn;
      const row = data as unknown as Record<string, unknown>;
      if (ownerCol && row[ownerCol] !== userId) {
        throw new ApiError(403, 'Forbidden.');
      }

      return;
    }

    if (this.ownership.writeRoles?.length && (!role || !this.ownership.writeRoles.includes(role))) {
      throw new ApiError(403, 'Forbidden.');
    }
  }

  async list(userId: string, role?: string) {
    let query = supabaseAdmin.from(this.tableName).select(this.selectClause);

    if (this.ownership.adminOnlyRead && role !== 'admin') {
      throw new ApiError(403, 'Forbidden.');
    }

    if (this.ownership.ownerColumn && this.ownership.restrictListToOwner && role !== 'admin') {
      query = query.eq(this.ownership.ownerColumn, userId);
    }

    const { data, error } = await query;
    if (error) throw new ApiError(500, `Failed to fetch ${this.tableName}.`, error);
    return data;
  }

  async getById(id: string, userId: string, role?: string) {
    if (this.ownership.adminOnlyRead && role !== 'admin') {
      throw new ApiError(403, 'Forbidden.');
    }

    let query = supabaseAdmin
      .from(this.tableName)
      .select(this.selectClause)
      .eq('id', id);

    if (this.ownership.ownerColumn && this.ownership.restrictGetToOwner && role !== 'admin') {
      query = query.eq(this.ownership.ownerColumn, userId);
    }

    const { data, error } = await query.single();

    if (error) throw new ApiError(404, `${this.tableName} record not found.`, error);
    return data;
  }

  async create(userId: string, role: string | undefined, payload: CrudCreateDto) {
    if (this.ownership.createRoles?.length && (!role || !this.ownership.createRoles.includes(role))) {
      throw new ApiError(403, 'Forbidden.');
    }

    const dataToInsert = this.ownership.ownerColumn
      ? { ...payload, [this.ownership.ownerColumn]: payload[this.ownership.ownerColumn] ?? userId }
      : payload;

    const { data, error } = await supabaseAdmin
      .from(this.tableName)
      .insert(dataToInsert)
      .select(this.selectClause)
      .single();

    if (error) throw new ApiError(500, `Failed to create ${this.tableName}.`, error);
    return data;
  }

  async update(id: string, userId: string, role: string | undefined, payload: CrudUpdateDto) {
    await this.assertCanMutate(id, userId, role);

    const { data, error } = await supabaseAdmin
      .from(this.tableName)
      .update(payload)
      .eq('id', id)
      .select(this.selectClause)
      .single();

    if (error) throw new ApiError(500, `Failed to update ${this.tableName}.`, error);
    return data;
  }

  async remove(id: string, userId: string, role: string | undefined) {
    await this.assertCanMutate(id, userId, role);

    const { error } = await supabaseAdmin.from(this.tableName).delete().eq('id', id);
    if (error) throw new ApiError(500, `Failed to delete ${this.tableName}.`, error);
    return { id };
  }
}
