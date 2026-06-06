import { useQuery } from '@tanstack/react-query';
import { api } from './axios';
import type { ApiResponse, Equipment } from '../types';

export function useApiList<T>(key: unknown[], url: string) {
  return useQuery({
    queryKey: key,
    queryFn: async () => (await api.get<ApiResponse<T[]>>(url)).data,
  });
}

export function useEquipment(params = '') {
  return useApiList<Equipment>(['equipment', params], `/equipment${params}`);
}

export function useUnreadCount() {
  return useQuery({
    queryKey: ['notifications', 'unread-count'],
    queryFn: async () => (await api.get<ApiResponse<{ count: number }>>('/notifications/unread-count')).data.data,
    refetchInterval: 30000,
  });
}
