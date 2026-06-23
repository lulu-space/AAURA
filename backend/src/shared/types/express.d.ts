import type { JwtPayload } from 'jsonwebtoken';

declare global {
  namespace Express {
    interface Request {
      authUser?: {
        id: string;
        email?: string;
        role?: string;
        jwt?: JwtPayload | string;
      };
    }
  }
}

export {};
