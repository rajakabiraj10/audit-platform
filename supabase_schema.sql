-- ============================================================
-- PRIME INFOSERV GRC PLATFORM — SUPABASE SCHEMA
-- Run this entire file in Supabase SQL Editor
-- ============================================================

-- 1. CLIENT PROFILES
create table if not exists clients (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  industry text,
  company_size text,
  it_environment text,
  regulatory_scope text[],
  contact_name text,
  contact_email text,
  contact_phone text,
  address text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 2. ENGAGEMENTS
create table if not exists engagements (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references clients(id) on delete cascade,
  client_name text not null,
  standard text not null,
  audit_type text not null,
  auditor_name text not null,
  auditor_email text,
  status text default 'In Progress',
  progress integer default 0,
  compliance_score integer default 0,
  total_controls integer default 0,
  assessed_controls integer default 0,
  compliant_count integer default 0,
  partial_count integer default 0,
  non_compliant_count integer default 0,
  ncr_count integer default 0,
  current_domain text,
  started_at timestamptz default now(),
  completed_at timestamptz,
  updated_at timestamptz default now()
);

-- 3. ASSESSMENT RESPONSES (every answer saved)
create table if not exists assessment_responses (
  id uuid primary key default gen_random_uuid(),
  engagement_id uuid references engagements(id) on delete cascade,
  control_ref text not null,
  domain_name text,
  answer text,           -- Y, P, N, X
  maturity_score integer,
  auditor_notes text,
  risk_level text,
  doc_checklist jsonb,   -- which documents were ticked
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(engagement_id, control_ref)
);

-- 4. NCRs (Non-Conformances)
create table if not exists ncrs (
  id uuid primary key default gen_random_uuid(),
  engagement_id uuid references engagements(id) on delete cascade,
  control_ref text not null,
  ncr_type text,         -- Major, Minor, Observation
  description text,
  evidence_required text,
  auditor_notes text,
  status text default 'Open',  -- Open, In Progress, Closed
  due_date date,
  closed_at timestamptz,
  created_at timestamptz default now()
);

-- 5. REPORTS (final generated reports)
create table if not exists reports (
  id uuid primary key default gen_random_uuid(),
  engagement_id uuid references engagements(id) on delete cascade,
  report_type text,      -- Gap Assessment, Stage 1, Stage 2, etc.
  summary_json jsonb,    -- full summary data
  gap_analysis_json jsonb,
  soa_json jsonb,
  risk_register_json jsonb,
  remediation_json jsonb,
  generated_at timestamptz default now(),
  generated_by text
);

-- ============================================================
-- ENABLE REALTIME (so dashboard updates live)
-- ============================================================
alter publication supabase_realtime add table engagements;
alter publication supabase_realtime add table assessment_responses;
alter publication supabase_realtime add table ncrs;

-- ============================================================
-- ROW LEVEL SECURITY — open for now, lock down later
-- ============================================================
alter table clients enable row level security;
alter table engagements enable row level security;
alter table assessment_responses enable row level security;
alter table ncrs enable row level security;
alter table reports enable row level security;

create policy "Public read" on clients for select using (true);
create policy "Public insert" on clients for insert with check (true);
create policy "Public update" on clients for update using (true);

create policy "Public read" on engagements for select using (true);
create policy "Public insert" on engagements for insert with check (true);
create policy "Public update" on engagements for update using (true);

create policy "Public read" on assessment_responses for select using (true);
create policy "Public insert" on assessment_responses for insert with check (true);
create policy "Public update" on assessment_responses for update using (true);

create policy "Public read" on ncrs for select using (true);
create policy "Public insert" on ncrs for insert with check (true);
create policy "Public update" on ncrs for update using (true);

create policy "Public read" on reports for select using (true);
create policy "Public insert" on reports for insert with check (true);
create policy "Public update" on reports for update using (true);

-- ============================================================
-- HELPFUL VIEWS
-- ============================================================
create or replace view engagement_summary as
select
  e.id,
  e.client_name,
  e.standard,
  e.audit_type,
  e.auditor_name,
  e.status,
  e.progress,
  e.compliance_score,
  e.compliant_count,
  e.partial_count,
  e.non_compliant_count,
  e.ncr_count,
  e.current_domain,
  e.started_at,
  e.updated_at,
  c.industry,
  c.contact_email
from engagements e
left join clients c on e.client_id = c.id
order by e.updated_at desc;
