-- Create the tasks table
CREATE TABLE IF NOT EXISTS public.tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  assigned_to TEXT,
  due_date TIMESTAMP WITH TIME ZONE,
  category TEXT,
  priority TEXT,
  suggested_actions JSONB,
  extracted_entities JSONB,
  status TEXT DEFAULT 'pending'
);

-- Create task_history table
CREATE TABLE IF NOT EXISTS public.task_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID REFERENCES public.tasks(id) ON DELETE CASCADE,
  action TEXT NOT NULL, -- created, updated, status_changed, completed
  old_value JSONB,
  new_value JSONB,
  changed_by TEXT,
  changed_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

-- Create policy to allow all operations for now (DEV MODE)
-- WARNING: In production, tighten this to authenticated users only.
CREATE POLICY "Enable all access for all users" ON public.tasks
FOR ALL USING (true) WITH CHECK (true);
