export interface StudentModel {
  id: string;
  user_id: string;
  university_id: string;
  major?: string | null;
  department?: string | null;
  academic_year?: number | null;
  created_at: string;
  updated_at: string;
}

