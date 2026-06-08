import axios from 'axios';
import { useAuthStore } from '../stores/authStore';

function resolveApiUrl() {
  const envUrl = import.meta.env.VITE_API_URL as string | undefined;
  const browserHost = window.location.hostname;
  const isLanAccess = browserHost !== 'localhost' && browserHost !== '127.0.0.1';

  if (isLanAccess && (!envUrl || envUrl.includes('localhost') || envUrl.includes('127.0.0.1'))) {
    return `http://${browserHost}:3001/api`;
  }

  return envUrl ?? 'http://localhost:3001/api';
}

const apiBaseUrl = resolveApiUrl();

export const api = axios.create({
  baseURL: apiBaseUrl,
  withCredentials: true,
});

api.interceptors.request.use((config) => {
  const token = useAuthStore.getState().accessToken;
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

api.interceptors.response.use(
  (res) => res,
  async (error) => {
    const original = error.config;
    if (error.response?.status === 401 && !original?._retry) {
      original._retry = true;
      try {
        const { data } = await axios.post(`${apiBaseUrl}/auth/refresh`, {}, { withCredentials: true });
        useAuthStore.getState().setAccessToken(data.data.accessToken);
        original.headers.Authorization = `Bearer ${data.data.accessToken}`;
        return api(original);
      } catch {
        useAuthStore.getState().logout();
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  },
);
