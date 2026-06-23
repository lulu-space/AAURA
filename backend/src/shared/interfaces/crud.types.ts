export type CrudCreateDto = Record<string, unknown>;
export type CrudUpdateDto = Record<string, unknown>;

export interface CrudOwnershipConfig {
  ownerColumn?: string;
  createRoles?: string[];
  adminOnlyRead?: boolean;
  restrictListToOwner?: boolean;
  restrictGetToOwner?: boolean;
  writeRoles?: string[];
}
