-- CotisApp — registre d'échéances + déductions de dette au partage
--
-- Miroir de la migration drift schemaVersion 5 -> 6
-- (lib/data/local/database.dart, lib/data/local/tables/echeances_table.dart,
-- lib/data/local/tables/partage_deductions_table.dart). À coller dans le
-- SQL Editor Supabase APRÈS 0001_init.sql et 0002_membres_sans_telephone.sql.
--
-- Voir DECISIONS.md : "Historique des cotisations" et "Déduction des
-- dettes au partage".

create table if not exists echeances (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id),
  cycle_id uuid not null references cycles(id),
  member_id uuid not null references members(id),
  echeance_date timestamptz not null,
  carnets_engages integer not null,
  montant_du_fcfa integer not null,
  montant_paye_fcfa integer not null default 0,
  arrieres_fcfa integer not null default 0,
  amende_fcfa integer not null default 0,
  statut text not null check (statut in ('paye', 'non_paye')),
  cotisation_id uuid references cotisations(id),
  amende_id uuid references amendes(id),
  recorded_by_phone text not null,
  recorded_at timestamptz not null default now(),
  previous_hash text,
  hash text not null
);

create table if not exists partage_deductions (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id),
  cycle_id uuid not null references cycles(id),
  member_id uuid not null references members(id),
  montant_brut_fcfa integer not null,
  dette_fcfa integer not null,
  montant_deduit_fcfa integer not null,
  montant_net_fcfa integer not null,
  pert_avec_fcfa integer not null default 0,
  recorded_by_phone text not null,
  recorded_at timestamptz not null default now(),
  previous_hash text,
  hash text not null
);

create index if not exists idx_echeances_cycle on echeances(cycle_id);
create index if not exists idx_echeances_member on echeances(member_id);
create index if not exists idx_echeances_date on echeances(echeance_date);
create index if not exists idx_partage_deductions_cycle on partage_deductions(cycle_id);
create index if not exists idx_partage_deductions_member on partage_deductions(member_id);

alter table echeances enable row level security;
alter table partage_deductions enable row level security;

-- ---- tables financières en ajout seul : select + insert, jamais update/delete ----

create policy echeances_select on echeances for select
  using (app_is_agent(group_id) or app_is_self_member(member_id));
create policy echeances_insert on echeances for insert
  with check (app_is_agent(group_id));

create policy partage_deductions_select on partage_deductions for select
  using (app_is_agent(group_id) or app_is_self_member(member_id));
create policy partage_deductions_insert on partage_deductions for insert
  with check (app_is_agent(group_id));
