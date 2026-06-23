export class CrudController {
    service;
    entityName;
    constructor(service, entityName) {
        this.service = service;
        this.entityName = entityName;
    }
    async list(req, res) {
        const data = await this.service.list(req.authUser.id, req.authUser?.role);
        res.json({ message: `${this.entityName} fetched successfully.`, data });
    }
    async getById(req, res) {
        const id = req.params.id;
        const data = await this.service.getById(id, req.authUser.id, req.authUser?.role);
        res.json({ message: `${this.entityName} fetched successfully.`, data });
    }
    async create(req, res) {
        const data = await this.service.create(req.authUser.id, req.authUser?.role, req.body);
        res.status(201).json({ message: `${this.entityName} created successfully.`, data });
    }
    async update(req, res) {
        const id = req.params.id;
        const data = await this.service.update(id, req.authUser.id, req.authUser?.role, req.body);
        res.json({ message: `${this.entityName} updated successfully.`, data });
    }
    async remove(req, res) {
        const id = req.params.id;
        const data = await this.service.remove(id, req.authUser.id, req.authUser?.role);
        res.json({ message: `${this.entityName} deleted successfully.`, data });
    }
}
