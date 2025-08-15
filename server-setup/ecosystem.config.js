// PM2 Configuration for StudX
module.exports = {
  apps: [
    {
      name: 'studx-backend',
      script: './backend/index.js',
      cwd: '/var/www/studx/current',
      instances: 2,  // 2 процесса для 2 vCPU
      exec_mode: 'cluster',
      watch: false,
      max_memory_restart: '1G',
      
      // Переменные окружения
      env: {
        NODE_ENV: 'production',
        PORT: 3000
      },
      
      // Обработка ошибок и перезапуск
      error_file: '/var/www/studx/shared/logs/error.log',
      out_file: '/var/www/studx/shared/logs/out.log',
      merge_logs: true,
      time: true,
      
      // Автоперезапуск при падении
      autorestart: true,
      max_restarts: 10,
      min_uptime: '10s',
      
      // Graceful shutdown
      kill_timeout: 5000,
      wait_ready: true,
      listen_timeout: 10000,
      
      // Мониторинг производительности
      instance_var: 'INSTANCE_ID',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
    }
  ]
};
