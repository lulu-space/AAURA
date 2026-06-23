import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import morgan from 'morgan';
import router from './routes/index.js';
import { env } from './config/env.js';
import { errorHandler } from './shared/middleware/error-handler.js';
import { notFoundHandler } from './shared/middleware/not-found.js';

export const app = express();

const corsOrigins = env.CORS_ORIGINS?.split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

app.use(helmet());
app.use(
  cors(
    corsOrigins?.length
      ? {
          origin: corsOrigins,
          credentials: true
        }
      : undefined
  )
);
app.use(express.json());
app.use(morgan('dev'));

app.use('/api/v1', router);
app.use(notFoundHandler);
app.use(errorHandler);
