import axios from 'axios';

const API = axios.create({
  baseURL: process.env.REACT_APP_API_URL || 'http://localhost:5000/api',
  timeout: 30000,
  headers: { 'Content-Type': 'application/json' }
});

// Retry механизм для надежности
API.interceptors.response.use(null, async (error) => {
  const { config } = error;
  if (!config || !config.retry) config.retry = 0;
  if (config.retry >= 3) return Promise.reject(error);
  config.retry += 1;
  await new Promise(res => setTimeout(res, 1000 * config.retry));
  return API(config);
});

export default API;