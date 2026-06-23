import type { NextFunction, Request, Response } from 'express';

import { ApiError } from '../../../core/errors/api-error.js';

import { supabaseAdmin } from '../../../config/supabase.js';

import { authService } from '../../../modules/auth/services/auth.service.js';



export const authenticateJwt = async (req: Request, _res: Response, next: NextFunction) => {

  const authHeader = req.headers.authorization;

  const token = authHeader?.startsWith('Bearer ') ? authHeader.slice(7) : null;



  if (!token) {

    return next(new ApiError(401, 'Unauthorized.', { reason: 'missing_bearer_token' }));

  }



  const {

    data: { user },

    error

  } = await supabaseAdmin.auth.getUser(token);



  if (error || !user) {

    return next(

      new ApiError(401, 'Unauthorized.', {

        reason: 'invalid_or_expired_token',

        supabaseError: error ?? null

      })

    );

  }



  let appUser: { role: string; is_suspended: boolean } | null = null;



  try {

    appUser = await authService.ensureApplicationUser(user.id, user.email ?? undefined);

  } catch (provisionError) {

    return next(

      new ApiError(503, 'Could not set up your campus account. Please try again.', provisionError)

    );

  }



  if (appUser.is_suspended) {

    return next(new ApiError(403, 'Account is suspended.'));

  }



  req.authUser = {

    id: user.id,

    email: user.email,

    role: appUser.role

  };



  next();

};


