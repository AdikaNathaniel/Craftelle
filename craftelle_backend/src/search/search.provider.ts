import { Logger, Provider } from '@nestjs/common';
import { Client } from '@elastic/elasticsearch';
import Redis from 'ioredis';
import { ELASTIC_SEARCH_CLIENT, REDIS_CLIENT } from './constants';

const logger = new Logger('RedisProvider');

export const elasticSearchProvider: Provider = {
  provide: ELASTIC_SEARCH_CLIENT,
  useFactory: () => {
    return new Client({
      node: process.env.ELASTICSEARCH_HOST || 'http://localhost:9200',
    });
  },
};

export const redisProvider: Provider = {
  provide: REDIS_CLIENT,
  useFactory: () => {
    // Disabled: never connect; cache calls reject immediately and SearchService skips the cache
    if (process.env.DISABLE_REDIS === 'true') {
      const disabled = () => Promise.reject(new Error('Redis is disabled'));
      return { get: disabled, set: disabled } as unknown as Redis;
    }

    const options = {
      maxRetriesPerRequest: 3,
      tls: process.env.REDIS_TLS === 'true' ? {} : undefined,
    };
    const client = process.env.REDIS_URL
      ? new Redis(process.env.REDIS_URL, options)
      : new Redis({
          ...options,
          host: process.env.REDIS_HOST || 'localhost',
          port: parseInt(process.env.REDIS_PORT, 10) || 6379,
          password: process.env.REDIS_PASSWORD,
        });

    client.on('error', (error) => {
      logger.warn(`Redis connection error: ${error.message}`);
    });
    return client;
  },
};