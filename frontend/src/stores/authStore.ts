import { create } from 'zustand';
import type { Role, User } from '../types';

type AuthState = {
  user: User | null;
  accessToken: string | null;
  setAuth: (user: User, accessToken: string) => void;
  setAccessToken: (accessToken: string) => void;
  logout: () => void;
  hasRole: (roles: Role[]) => boolean;
};

const stored = localStorage.getItem('labin-auth');
const initial = stored ? JSON.parse(stored) as Pick<AuthState, 'user' | 'accessToken'> : { user: null, accessToken: null };

export const useAuthStore = create<AuthState>((set, get) => ({
  user: initial.user,
  accessToken: initial.accessToken,
  setAuth: (user, accessToken) => {
    localStorage.setItem('labin-auth', JSON.stringify({ user, accessToken }));
    set({ user, accessToken });
  },
  setAccessToken: (accessToken) => {
    localStorage.setItem('labin-auth', JSON.stringify({ user: get().user, accessToken }));
    set({ accessToken });
  },
  logout: () => {
    localStorage.removeItem('labin-auth');
    set({ user: null, accessToken: null });
  },
  hasRole: (roles) => {
    const role = get().user?.role;
    return !!role && roles.includes(role);
  },
}));
