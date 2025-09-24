export interface Project {
  id: number;
  title: string;
  description: string;
  short_description: string;
  type: string;
  icon: string;
  github_url: string;
  live_url: string;
  technologies: string[];
  active: boolean;
  github_active: boolean;
}

export interface Skill {
  id: number;
  name: string;
  category: string;
  proficiency: number;
  icon: string;
  order: number;
}

export interface Experience {
  id: number;
  title: string;
  company: string;
  start_date: string;
  end_date?: string;
  current: boolean;
  description: string;
  technologies: string[];
  order: number;
}

export interface Visitor {
  id: number;
  ip: string;
  user_agent: string;
  country?: string;
  city?: string;
  first_visit: string;
  last_visit: string;
  visit_count: number;
}

export interface Content {
  key: string;
  value: {
    title?: string;
    description?: string;
    highlights?: Array<{ icon: string; text: string }>;
    email?: string;
    location?: string;
    linkedin?: string;
    github?: string;
    availability?: string;
    subtitle?: string;
  };
}

export interface ApiResponse<T> {
  data: T;
  message?: string;
  error?: string;
}

export interface AnalyticsData {
  total_visitors: number;
  unique_visitors: number;
  total_views: number;
  project_views: Record<number, number>;
} 