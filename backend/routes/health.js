// Health Check API для StudX
// Проверяет работоспособность всех компонентов системы

const express = require('express');
const router = express.Router();

// Базовый health check - минимальная проверка
router.get('/health', async (req, res) => {
    try {
        const health = {
            status: 'ok',
            timestamp: new Date().toISOString(),
            uptime: process.uptime(),
            version: process.env.VERSION || '1.0.0',
            env: process.env.NODE_ENV || 'development'
        };

        res.status(200).json(health);
    } catch (error) {
        res.status(503).json({
            status: 'error',
            message: error.message
        });
    }
});

// Детальный health check - проверка всех компонентов
router.get('/health/detailed', async (req, res) => {
    const startTime = Date.now();
    const checks = {
        timestamp: new Date().toISOString(),
        version: process.env.VERSION || '1.0.0',
        env: process.env.NODE_ENV || 'development',
        uptime: process.uptime(),
        checks: {}
    };

    // Проверка памяти
    const memoryUsage = process.memoryUsage();
    const os = require('os');
    const totalMemory = os.totalmem();
    const freeMemory = os.freemem();
    
    checks.checks.memory = {
        status: 'ok',
        details: {
            process: {
                rss: `${Math.round(memoryUsage.rss / 1024 / 1024)}MB`,
                heapUsed: `${Math.round(memoryUsage.heapUsed / 1024 / 1024)}MB`,
                heapTotal: `${Math.round(memoryUsage.heapTotal / 1024 / 1024)}MB`
            },
            system: {
                total: `${Math.round(totalMemory / 1024 / 1024)}MB`,
                free: `${Math.round(freeMemory / 1024 / 1024)}MB`,
                percentage: Math.round(((totalMemory - freeMemory) / totalMemory) * 100)
            }
        }
    };

    // Предупреждение если память заканчивается
    if (memoryUsage.heapUsed / memoryUsage.heapTotal > 0.9) {
        checks.checks.memory.status = 'warning';
        checks.checks.memory.message = 'High memory usage';
    }

    // Проверка CPU
    const cpus = os.cpus();
    const loadAverage = os.loadavg();
    
    checks.checks.cpu = {
        status: 'ok',
        details: {
            cores: cpus.length,
            loadAverage: {
                '1min': loadAverage[0].toFixed(2),
                '5min': loadAverage[1].toFixed(2),
                '15min': loadAverage[2].toFixed(2)
            }
        }
    };

    // Предупреждение при высокой загрузке
    if (loadAverage[0] > cpus.length * 0.8) {
        checks.checks.cpu.status = 'warning';
        checks.checks.cpu.message = 'High CPU load';
    }

    // Проверка PostgreSQL
    if (process.env.DB_HOST) {
        try {
            const { Pool } = require('pg');
            const pgPool = new Pool({
                host: process.env.DB_HOST || 'localhost',
                port: process.env.DB_PORT || 5432,
                database: process.env.DB_NAME || 'studx_db',
                user: process.env.DB_USER || 'studx_user',
                password: process.env.DB_PASSWORD,
                max: 1,
                connectionTimeoutMillis: 2000,
            });

            const pgStart = Date.now();
            const result = await pgPool.query('SELECT NOW() as time, version() as version');
            const pgLatency = Date.now() - pgStart;
            await pgPool.end();

            checks.checks.postgresql = {
                status: 'ok',
                latency: `${pgLatency}ms`,
                details: {
                    serverTime: result.rows[0].time,
                    version: result.rows[0].version.split(' ')[1]
                }
            };

            if (pgLatency > 100) {
                checks.checks.postgresql.status = 'warning';
                checks.checks.postgresql.message = 'High database latency';
            }
        } catch (error) {
            checks.checks.postgresql = {
                status: 'error',
                message: 'Database connection failed',
                error: error.message
            };
        }
    }

    // Проверка Redis
    if (process.env.REDIS_HOST || process.env.REDIS_PASSWORD) {
        try {
            const redis = require('redis');
            const redisClient = redis.createClient({
                host: process.env.REDIS_HOST || 'localhost',
                port: process.env.REDIS_PORT || 6379,
                password: process.env.REDIS_PASSWORD
            });

            const redisStart = Date.now();
            await new Promise((resolve, reject) => {
                redisClient.ping((err, result) => {
                    if (err) reject(err);
                    else resolve(result);
                });
            });
            const redisLatency = Date.now() - redisStart;

            checks.checks.redis = {
                status: 'ok',
                latency: `${redisLatency}ms`
            };

            if (redisLatency > 50) {
                checks.checks.redis.status = 'warning';
                checks.checks.redis.message = 'High Redis latency';
            }

            redisClient.quit();
        } catch (error) {
            checks.checks.redis = {
                status: 'error',
                message: 'Redis connection failed',
                error: error.message
            };
        }
    }

    // Определение общего статуса
    const hasError = Object.values(checks.checks).some(check => check.status === 'error');
    const hasWarning = Object.values(checks.checks).some(check => check.status === 'warning');
    
    checks.status = hasError ? 'error' : hasWarning ? 'warning' : 'ok';
    checks.responseTime = `${Date.now() - startTime}ms`;

    const statusCode = hasError ? 503 : 200;
    res.status(statusCode).json(checks);
});

// Готовность к приему трафика (для load balancer)
router.get('/health/ready', async (req, res) => {
    try {
        // Быстрая проверка только критичных компонентов
        const checks = [];
        
        if (process.env.DB_HOST) {
            const { Pool } = require('pg');
            const pgPool = new Pool({
                host: process.env.DB_HOST || 'localhost',
                database: process.env.DB_NAME || 'studx_db',
                user: process.env.DB_USER || 'studx_user',
                password: process.env.DB_PASSWORD,
                max: 1,
                connectionTimeoutMillis: 2000,
            });
            checks.push(pgPool.query('SELECT 1').then(() => pgPool.end()));
        }

        if (process.env.REDIS_PASSWORD) {
            const redis = require('redis');
            const redisClient = redis.createClient({
                host: process.env.REDIS_HOST || 'localhost',
                port: process.env.REDIS_PORT || 6379,
                password: process.env.REDIS_PASSWORD
            });
            checks.push(new Promise((resolve, reject) => {
                redisClient.ping((err) => {
                    redisClient.quit();
                    if (err) reject(err);
                    else resolve();
                });
            }));
        }

        await Promise.all(checks);

        res.status(200).json({
            ready: true,
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        res.status(503).json({
            ready: false,
            error: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

// Liveness probe (для Kubernetes/Docker)
router.get('/health/live', (req, res) => {
    res.status(200).json({
        live: true,
        pid: process.pid,
        timestamp: new Date().toISOString()
    });
});

module.exports = router;
