export type Role = 'STUDENT' | 'LECTURER' | 'STAFF' | 'ADMIN';

export type User = {
  id: string;
  name: string;
  email: string;
  nim?: string;
  role: Role;
  university?: string;
  faculty?: string;
  studyProgram?: string;
  phone?: string;
  avatarUrl?: string;
};

export type ApiResponse<T> = {
  success: boolean;
  data: T;
  meta?: { page: number; limit: number; total: number };
};

export type Equipment = {
  id: string;
  name: string;
  category: string;
  description: string;
  specifications?: string;
  totalStock: number;
  availableStock: number;
  condition: string;
  imageUrl?: string;
};
