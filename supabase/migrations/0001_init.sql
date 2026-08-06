-- CotisApp — schéma PostgreSQL initial (Supabase)
--
-- Miroir du schéma `drift` local (lib/data/local/tables/*.dart), schemaVersion 2.
-- Ce fichier est écrit pour être collé tel quel dans l'éditeur SQL Supabase
-- (Dashboard → SQL Editor → New query), ou exécuté via `supabase db push`
-- si la CLI Supabase est installée plus tard.
--
-- Principes respectés (voir skills du projet) :
--  - two-tier-access-model : le filtrage agent/membre est appliqué ICI,
--    au niveau base de données (RLS), jamais seulement côté client.
--  - member-consent-rules : un prêt n'est confirmé que par le membre
--    concerné — seule sa propre confirmation peut insérer une ligne
--    dans pret_confirmations en son nom.
--  - avec-business-rules : le fonds de solidarité et les tables
--    financières restent en ajout seul (aucune politique UPDATE/DELETE
--    n'est créée pour elles — sans politique, Postgres refuse l'action).
--
-- Ce que ce fichier NE fait PAS (volontairement, pour rester réversible) :
--  - Pas de colonnes de synchronisation (updated_at, deleted_at, etc.) —
--    seront ajoutées avec la conception de la couche de synchronisation
--    offline-first elle-même, pas avant (éviter la surconstruction).
--  - Pas de configuration Auth/Twilio — fait séparément dans le Dashboard.

-- ============================================================
-- 1. Tables
-- ============================================================

create table if not exists groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  cycle_duration_months integer not null default 9,
  meeting_frequency text not null default 'mensuelle'
    check (meeting_frequency in ('hebdomadaire', 'bimensuelle', 'mensuelle')),
  created_at timestamptz not null default now()
);

create table if not exists members (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id),
  full_name text not null,
  phone_number text not null,
  joined_at timestamptz not null default now(),
  active boolean not null default true
);

create table if not exists cycles (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id),
  cycle_number integer not null,
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  part_value_fcfa integer not null,
  interest_rate_percent double precision not null,
  late_fee_fcfa integer not null default 0,
  status text not null default 'en_cours'
    check (status in ('en_cours', 'cloture'))
);

create table if not exists agent_assignments (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id),
  member_id uuid references members(id),
  phone_number text not null,
  role text not null,
  assigned_at timestamptz not null default now(),
  previous_hash text,
  hash text not null
);

create table if not exists agent_assignment_revocations (
  id uuid primary key default gen_random_uuid(),
  assignment_id uuid not null references agent_assignments(id),
  revoked_at timestamptz not null default now(),
  previous_hash text,
  hash text not null
);

create table if not exists cotisations (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id),
  cycle_id uuid not null references cycles(id),
  member_id uuid not null references members(id),
  parts_count integer not null,
  source text not null default 'cash' check (source in ('cash', 'distance')),
  recorded_by_phone text not null,
  recorded_at timestamptz not null default now(),
  previous_hash text,
  hash text not null,
  provenance text not null default 'direct' check (provenance in ('direct', 'importe')),
  est_approximatif boolean not null default false
);

create table if not exists amendes (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id),
  cycle_id uuid not null references cycles(id),
  member_id uuid not null references members(id),
  montant_fcfa integer not null,
  motif text not null,
  recorded_by_phone text not null,
  recorded_at timestamptz not null default now(),
  previous_hash text,
  hash text not null,
  provenance text not null default 'direct' check (provenance in ('direct', 'importe')),
  est_approximatif boolean not null default false
);

create table if not exists fonds_solidarite_contributions (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id),
  cycle_id uuid not null references cycles(id),
  member_id uuid references members(id),
  montant_fcfa integer not null,
  motif text not null,
  recorded_by_phone text not null,
  recorded_at timestamptz not null default now(),
  previous_hash text,
  hash text not null,
  provenance text not null default 'direct' check (provenance in ('direct', 'importe')),
  est_approximatif boolean not null default false
);

create table if not exists prets (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id),
  cycle_id uuid not null references cycles(id),
  member_id uuid not null references members(id),
  principal_fcfa integer not null,
  interest_rate_percent double precision not null,
  initiated_by_phone text not null,
  confirmation_code text not null,
  created_at timestamptz not null default now(),
  previous_hash text,
  hash text not null,
  provenance text not null default 'direct' check (provenance in ('direct', 'importe')),
  est_approximatif boolean not null default false
);

create table if not exists pret_confirmations (
  id uuid primary key default gen_random_uuid(),
  pret_id uuid not null references prets(id),
  code_saisi text not null,
  confirmed_by_phone text not null,
  confirmed_at timestamptz not null default now(),
  previous_hash text,
  hash text not null
);

create table if not exists pret_remboursements (
  id uuid primary key default gen_random_uuid(),
  pret_id uuid not null references prets(id),
  montant_fcfa integer not null,
  recorded_by_phone text not null,
  recorded_at timestamptz not null default now(),
  previous_hash text,
  hash text not null,
  provenance text not null default 'direct' check (provenance in ('direct', 'importe')),
  est_approximatif boolean not null default false
);

create table if not exists pret_annulations (
  id uuid primary key default gen_random_uuid(),
  pret_id uuid not null references prets(id),
  raison text not null,
  annule_par_phone text not null,
  annule_at timestamptz not null default now(),
  previous_hash text,
  hash text not null
);

create index if not exists idx_members_group on members(group_id);
create index if not exists idx_members_phone on members(phone_number);
create index if not exists idx_cycles_group on cycles(group_id);
create index if not exists idx_cotisations_cycle on cotisations(cycle_id);
create index if not exists idx_cotisations_member on cotisations(member_id);
create index if not exists idx_amendes_cycle on amendes(cycle_id);
create index if not exists idx_amendes_member on amendes(member_id);
create index if not exists idx_prets_cycle on prets(cycle_id);
create index if not exists idx_prets_member on prets(member_id);
create index if not exists idx_pret_confirmations_pret on pret_confirmations(pret_id);
create index if not exists idx_pret_remboursements_pret on pret_remboursements(pret_id);
create index if not exists idx_pret_annulations_pret on pret_annulations(pret_id);
create index if not exists idx_fonds_solidarite_cycle on fonds_solidarite_contributions(cycle_id);
create index if not exists idx_agent_assignments_group on agent_assignments(group_id);
create index if not exists idx_agent_assignments_phone on agent_assignments(phone_number);

-- ============================================================
-- 2. Fonctions d'aide pour la sécurité au niveau ligne
-- ============================================================
-- Hypothèse : Supabase Auth (téléphone + Twilio) stocke le numéro
-- confirmé dans auth.users.phone au format que l'app utilise pour
-- members.phone_number / agent_assignments.phone_number (même
-- normalisation des deux côtés — à vérifier au branchement de l'auth
-- réelle, voir ROADMAP.md étape 3).

create or replace function app_current_phone()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select phone from auth.users where id = auth.uid();
$$;

-- Vrai si l'utilisateur connecté est un agent actif (non révoqué) du
-- groupe donné. Seul le rôle applicatif 'agent' donne l'accès complet —
-- les rôles du comité (presidente, secretaire...) sont informatifs.
create or replace function app_is_agent(p_group_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from agent_assignments aa
    where aa.group_id = p_group_id
      and aa.role = 'agent'
      and aa.phone_number = app_current_phone()
      and not exists (
        select 1 from agent_assignment_revocations r
        where r.assignment_id = aa.id
      )
  );
$$;

-- Vrai si l'utilisateur connecté EST le membre donné (accès membre —
-- lecture seule à ses propres données uniquement).
create or replace function app_is_self_member(p_member_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from members m
    where m.id = p_member_id
      and m.phone_number = app_current_phone()
  );
$$;

-- Groupe auquel appartient une affectation de rôle donnée — utile pour
-- agent_assignment_revocations, qui n'a pas de group_id directement.
create or replace function app_group_of_assignment(p_assignment_id uuid)
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select group_id from agent_assignments where id = p_assignment_id;
$$;

-- Groupe auquel appartient un prêt donné — utile pour les tables filles
-- (pret_confirmations, pret_remboursements, pret_annulations) qui n'ont
-- pas de group_id directement.
create or replace function app_group_of_pret(p_pret_id uuid)
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select group_id from prets where id = p_pret_id;
$$;

create or replace function app_member_of_pret(p_pret_id uuid)
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select member_id from prets where id = p_pret_id;
$$;

-- ============================================================
-- 3. Row-Level Security
-- ============================================================

alter table groups enable row level security;
alter table members enable row level security;
alter table cycles enable row level security;
alter table agent_assignments enable row level security;
alter table agent_assignment_revocations enable row level security;
alter table cotisations enable row level security;
alter table amendes enable row level security;
alter table fonds_solidarite_contributions enable row level security;
alter table prets enable row level security;
alter table pret_confirmations enable row level security;
alter table pret_remboursements enable row level security;
alter table pret_annulations enable row level security;

-- ---- groups ----
-- Lecture : agent du groupe, ou membre du groupe.
create policy groups_select on groups for select
  using (app_is_agent(id) or exists (
    select 1 from members m where m.group_id = groups.id and m.phone_number = app_current_phone()
  ));
-- Création : tout utilisateur authentifié peut créer un groupe (il en
-- devient agent via affecterRole juste après, côté app).
create policy groups_insert on groups for insert
  with check (auth.uid() is not null);
-- Modification : agent du groupe uniquement. Pas de suppression (aucune
-- politique delete = refusé par défaut).
create policy groups_update on groups for update
  using (app_is_agent(id));

-- ---- members ----
create policy members_select on members for select
  using (app_is_agent(group_id) or phone_number = app_current_phone());
create policy members_insert on members for insert
  with check (app_is_agent(group_id));
create policy members_update on members for update
  using (app_is_agent(group_id));

-- ---- cycles ----
create policy cycles_select on cycles for select
  using (app_is_agent(group_id) or exists (
    select 1 from members m where m.group_id = cycles.group_id and m.phone_number = app_current_phone()
  ));
create policy cycles_insert on cycles for insert
  with check (app_is_agent(group_id));
create policy cycles_update on cycles for update
  using (app_is_agent(group_id));

-- ---- agent_assignments / revocations ----
-- Administratif : réservé aux agents déjà en place sur le groupe.
create policy agent_assignments_select on agent_assignments for select
  using (app_is_agent(group_id) or phone_number = app_current_phone());
create policy agent_assignments_insert on agent_assignments for insert
  with check (
    -- premier agent d'un groupe tout juste créé (aucun agent actif
    -- encore), ou ajout par un agent déjà actif
    not exists (select 1 from agent_assignments aa2 where aa2.group_id = agent_assignments.group_id and aa2.role = 'agent')
    or app_is_agent(group_id)
  );
create policy agent_assignment_revocations_select on agent_assignment_revocations for select
  using (app_is_agent(app_group_of_assignment(assignment_id)));
create policy agent_assignment_revocations_insert on agent_assignment_revocations for insert
  with check (app_is_agent(app_group_of_assignment(assignment_id)));

-- ---- tables financières en ajout seul : select + insert, jamais update/delete ----

create policy cotisations_select on cotisations for select
  using (app_is_agent(group_id) or app_is_self_member(member_id));
create policy cotisations_insert on cotisations for insert
  with check (app_is_agent(group_id));

create policy amendes_select on amendes for select
  using (app_is_agent(group_id) or app_is_self_member(member_id));
create policy amendes_insert on amendes for insert
  with check (app_is_agent(group_id));

create policy fonds_solidarite_select on fonds_solidarite_contributions for select
  using (app_is_agent(group_id) or (member_id is not null and app_is_self_member(member_id)));
create policy fonds_solidarite_insert on fonds_solidarite_contributions for insert
  with check (app_is_agent(group_id));

create policy prets_select on prets for select
  using (app_is_agent(group_id) or app_is_self_member(member_id));
create policy prets_insert on prets for insert
  with check (app_is_agent(group_id));

-- pret_confirmations : seul le membre concerné par CE prêt peut inséré
-- sa propre confirmation (skill member-consent-rules — personne d'autre
-- ne peut confirmer à sa place, pas même l'agent).
create policy pret_confirmations_select on pret_confirmations for select
  using (app_is_agent(app_group_of_pret(pret_id)) or app_is_self_member(app_member_of_pret(pret_id)));
create policy pret_confirmations_insert on pret_confirmations for insert
  with check (
    confirmed_by_phone = app_current_phone()
    and app_is_self_member(app_member_of_pret(pret_id))
  );

create policy pret_remboursements_select on pret_remboursements for select
  using (app_is_agent(app_group_of_pret(pret_id)) or app_is_self_member(app_member_of_pret(pret_id)));
create policy pret_remboursements_insert on pret_remboursements for insert
  with check (app_is_agent(app_group_of_pret(pret_id)));

create policy pret_annulations_select on pret_annulations for select
  using (app_is_agent(app_group_of_pret(pret_id)) or app_is_self_member(app_member_of_pret(pret_id)));
create policy pret_annulations_insert on pret_annulations for insert
  with check (app_is_agent(app_group_of_pret(pret_id)));
