import type { Request, Response } from 'express';
import type { SupabaseCrudService } from './supabase-crud.service.js';

export class CrudController {
  constructor(private readonly service: SupabaseCrudService, private readonly entityName: string) {}

  async list(req: Request, res: Response) {
    const data = await this.service.list(req.authUser!.id, req.authUser?.role);
    res.json({ message: `${this.entityName} fetched successfully.`, data });
  }

  async getById(req: Request, res: Response) {
    const id = req.params.id as string;
    const data = await this.service.getById(id, req.authUser!.id, req.authUser?.role);
    res.json({ message: `${this.entityName} fetched successfully.`, data });
  }

  async create(req: Request, res: Response) {
    const data = await this.service.create(req.authUser!.id, req.authUser?.role, req.body);
    res.status(201).json({ message: `${this.entityName} created successfully.`, data });
  }

  async update(req: Request, res: Response) {
    const id = req.params.id as string;
    const data = await this.service.update(id, req.authUser!.id, req.authUser?.role, req.body);
    res.json({ message: `${this.entityName} updated successfully.`, data });
  }

  async remove(req: Request, res: Response) {
    const id = req.params.id as string;
    const data = await this.service.remove(id, req.authUser!.id, req.authUser?.role);
    res.json({ message: `${this.entityName} deleted successfully.`, data });
  }
}
