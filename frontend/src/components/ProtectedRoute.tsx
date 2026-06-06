import { Navigate, Outlet } from 'react-router-dom';
import type { Role } from '../types';
import { useAuthStore } from '../stores/authStore';

export function ProtectedRoute({ roles }: { roles?: Role[] }) {
  const { user, accessToken } = useAuthStore();
  if (!user || !accessToken) return <Navigate to="/login" replace />;
  if (roles && !roles.includes(user.role)) return <Navigate to="/unauthorized" replace />;
  return <Outlet />;
}
