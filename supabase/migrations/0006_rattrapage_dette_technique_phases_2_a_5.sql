-- CotisApp — rattrapage de la dette technique Postgres (schemaVersion
-- drift 4-5 puis 10-22, lib/data/local/database.dart)
--
-- Constatée le 2026-08-08 en écrivant 0004_carnets_et_seances.sql (voir
-- son en-tête) : le miroir Postgres a arrêté de suivre le schéma drift
-- local peu après le tout premier import, alors que le développement a
-- continué (Phases 2 à 5, voir CHANGELOG.md/DECISIONS.md). Sans
-- conséquence jusqu'ici car la synchronisation reste inactive (bloquée
-- par l'authentification Twilio, voir ROADMAP.md étape 2) — mais à
-- combler avant de la brancher, pas avant. Ce fichier ferme tout
-- l'écart d'un coup plutôt que de rejouer 12 migrations séparées.
--
-- À coller dans le SQL Editor Supabase APRÈS 0001 à 0005.
--
-- Comme pour 0004/0005 : aucun groupe réel n'utilise la synchronisation
-- Supabase pour l'instant, donc pas de rétro-remplissage nécessaire —
-- les nouvelles colonnes restent nullable/à zéro pour tout ce qui a
-- été écrit avant (rien n'a jamais été écrit en production ici).
--
-- Pour une table introduite en cours d'historique drift et qui a
-- ensuite gagné des colonnes (ex. motifs_amende : créée à la version
-- 10, complétée à la version 14), ce fichier la crée directement avec
-- sa structure **actuelle** plutôt que de rejouer les étapes
-- intermédiaires — même principe que 0004 pour carnets_engages.

-- ============================================================
-- 1. Colonnes manquantes sur des tables existantes
-- ============================================================

-- schemaVersion 3 -> 4 : jour de paiement fixe, durée de prêt.
alter table groups
  add column if not exists payment_day_of_week integer check (payment_day_of_week between 1 and 7),
  add column if not exists payment_day_of_month1 integer check (payment_day_of_month1 between 1 and 31),
  add column if not exists payment_day_of_month2 integer check (payment_day_of_month2 between 1 and 31);

alter table cycles
  add column if not exists loan_duration_days integer not null default 90;

alter table prets
  add column if not exists duree_jours integer;

-- schemaVersion 4 -> 5 : amendes automatiques (mécanisme depuis
-- remplacé par la saisie manuelle, voir DECISIONS.md, "Amende de
-- retard retirée" — colonnes conservées, jamais rétroactivement
-- vraies pour une amende déjà écrite).
alter table amendes
  add column if not exists est_auto_generee boolean not null default false,
  add column if not exists confirmed_at timestamptz;

-- schemaVersion 10 -> 11.
alter table amendes
  add column if not exists reviewed_at timestamptz;

-- schemaVersion 14 -> 15 : amende propre à un carnet.
alter table amendes
  add column if not exists carnet_numero integer not null default 1 check (carnet_numero in (1, 2)),
  add column if not exists echeance_date timestamptz,
  add column if not exists motif_code_systeme text;

-- schemaVersion 16 -> 17 : fonds de solidarité obligatoire.
alter table groups
  add column if not exists montant_solidarite_obligatoire_fcfa integer not null default 0;

-- schemaVersion 18 -> 19 : dette de prêt "au rouge".
alter table groups
  add column if not exists montant_amende_sortie_rouge_fcfa integer not null default 0;

alter table prets
  add column if not exists renouvele_pret_id uuid references prets(id),
  add column if not exists est_au_rouge_des_le_depart boolean not null default false;

-- schemaVersion 6 -> 7 (jamais miré) : `echeances` a été entièrement
-- recréée en drift (`carnets_engages`, l'ancien multiplicateur, n'a
-- jamais existé dans le nouveau modèle par carnet). La colonne créée
-- par 0003 sous ce nom est un vestige de l'ancienne structure —
-- jamais lue ni écrite par le code actuel.
alter table echeances
  drop column if exists carnets_engages;

-- ============================================================
-- 2. Nouvelles tables (dans l'ordre de leurs dépendances)
-- ============================================================

-- schemaVersion 4 -> 5.
create table if not exists amende_annulations (
  id uuid primary key default gen_random_uuid(),
  amende_id uuid not null references amendes(id),
  raison text not null,
  annule_par_phone text not null,
  annule_at timestamptz not null default now(),
  previous_hash text,
  hash text not null
);

-- schemaVersion 9 -> 10, complétée à la version 14 (description,
-- code_systeme) — créée directement avec sa structure actuelle.
create table if not exists motifs_amende (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id),
  libelle text not null,
  montant_fcfa integer not null,
  description text,
  code_systeme text,
  actif boolean not null default true,
  created_at timestamptz not null default now()
);

-- schemaVersion 11 -> 12.
create table if not exists partage_paiement_confirmations (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id),
  cycle_id uuid not null references cycles(id),
  member_id uuid not null references members(id),
  confirmed_at timestamptz not null default now(),
  confirmed_by_phone text not null,
  unique (cycle_id, member_id)
);

-- schemaVersion 12 -> 13.
create table if not exists carnets (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id),
  member_id uuid not null references members(id),
  carnet_numero integer not null check (carnet_numero in (1, 2)),
  numero_serie text not null,
  created_at timestamptz not null default now(),
  unique (member_id, carnet_numero),
  unique (group_id, numero_serie)
);

-- schemaVersion 15 -> 16.
create table if not exists amende_paiements (
  id uuid primary key default gen_random_uuid(),
  amende_id uuid not null references amendes(id),
  montant_fcfa integer not null,
  recorded_by_phone text not null,
  recorded_at timestamptz not null default now(),
  previous_hash text,
  hash text not null
);

-- schemaVersion 17 -> 18 : créée avant l'ajout de la colonne qui la
-- référence sur fonds_solidarite_contributions, plus bas.
create table if not exists cotisations_exceptionnelles (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id),
  cycle_id uuid not null references cycles(id),
  motif text not null,
  montant_fcfa integer not null,
  date_limite timestamptz not null,
  created_by_phone text not null,
  created_at timestamptz not null default now(),
  previous_hash text,
  hash text not null
);

alter table fonds_solidarite_contributions
  add column if not exists cotisation_exceptionnelle_id uuid references cotisations_exceptionnelles(id);

-- schemaVersion 21 -> 22.
alter table fonds_solidarite_contributions
  add column if not exists est_deduction_automatique boolean not null default false;

-- schemaVersion 19 -> 20 : créées avant la colonne prets.demande_id
-- qui les référence, plus bas.
create table if not exists pret_demandes (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id),
  cycle_id uuid not null references cycles(id),
  member_id uuid not null references members(id),
  montant_demande_fcfa integer not null,
  recorded_by_phone text not null,
  created_at timestamptz not null default now(),
  previous_hash text,
  hash text not null
);

create table if not exists pret_demande_refus (
  id uuid primary key default gen_random_uuid(),
  demande_id uuid not null references pret_demandes(id),
  recorded_by_phone text not null,
  refused_at timestamptz not null default now(),
  previous_hash text,
  hash text not null
);

alter table prets
  add column if not exists demande_id uuid references pret_demandes(id);

-- schemaVersion 20 -> 21.
create table if not exists presence_anticipee (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id),
  cycle_id uuid not null references cycles(id),
  member_id uuid not null references members(id),
  carnet_numero integer not null,
  echeance_date timestamptz not null,
  code_systeme text not null,
  recorded_by_phone text not null,
  recorded_at timestamptz not null,
  unique (cycle_id, member_id, carnet_numero, echeance_date)
);

-- ============================================================
-- 3. Index
-- ============================================================

create index if not exists idx_amende_annulations_amende on amende_annulations(amende_id);
create index if not exists idx_motifs_amende_group on motifs_amende(group_id);
create index if not exists idx_partage_paiement_confirmations_cycle on partage_paiement_confirmations(cycle_id);
create index if not exists idx_carnets_group on carnets(group_id);
create index if not exists idx_carnets_member on carnets(member_id);
create index if not exists idx_amende_paiements_amende on amende_paiements(amende_id);
create index if not exists idx_cotisations_exceptionnelles_cycle on cotisations_exceptionnelles(cycle_id);
create index if not exists idx_pret_demandes_cycle on pret_demandes(cycle_id);
create index if not exists idx_pret_demande_refus_demande on pret_demande_refus(demande_id);
create index if not exists idx_presence_anticipee_cycle on presence_anticipee(cycle_id);

-- ============================================================
-- 4. Fonctions d'aide RLS supplémentaires
-- ============================================================

create or replace function app_group_of_amende(p_amende_id uuid)
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select group_id from amendes where id = p_amende_id;
$$;

create or replace function app_member_of_amende(p_amende_id uuid)
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select member_id from amendes where id = p_amende_id;
$$;

create or replace function app_group_of_demande(p_demande_id uuid)
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select group_id from pret_demandes where id = p_demande_id;
$$;

create or replace function app_member_of_demande(p_demande_id uuid)
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select member_id from pret_demandes where id = p_demande_id;
$$;

-- ============================================================
-- 5. Row-Level Security
-- ============================================================

alter table amende_annulations enable row level security;
alter table motifs_amende enable row level security;
alter table partage_paiement_confirmations enable row level security;
alter table carnets enable row level security;
alter table amende_paiements enable row level security;
alter table cotisations_exceptionnelles enable row level security;
alter table pret_demandes enable row level security;
alter table pret_demande_refus enable row level security;
alter table presence_anticipee enable row level security;

-- ---- amende_annulations : financière en ajout seul (comme
-- pret_annulations) ----
create policy amende_annulations_select on amende_annulations for select
  using (app_is_agent(app_group_of_amende(amende_id)) or app_is_self_member(app_member_of_amende(amende_id)));
create policy amende_annulations_insert on amende_annulations for insert
  with check (app_is_agent(app_group_of_amende(amende_id)));

-- ---- motifs_amende : configuration (comme carnets_engages) ----
create policy motifs_amende_select on motifs_amende for select
  using (app_is_agent(group_id) or exists (
    select 1 from members m where m.group_id = motifs_amende.group_id and m.phone_number = app_current_phone()
  ));
create policy motifs_amende_insert on motifs_amende for insert
  with check (app_is_agent(group_id));
create policy motifs_amende_update on motifs_amende for update
  using (app_is_agent(group_id));

-- ---- partage_paiement_confirmations : workflow, annulable librement
-- avant clôture (voir AppDatabase.annulerConfirmationPaiementMembre)
-- ----
create policy partage_paiement_confirmations_select on partage_paiement_confirmations for select
  using (app_is_agent(group_id) or app_is_self_member(member_id));
create policy partage_paiement_confirmations_insert on partage_paiement_confirmations for insert
  with check (app_is_agent(group_id));
create policy partage_paiement_confirmations_delete on partage_paiement_confirmations for delete
  using (app_is_agent(group_id));

-- ---- carnets : configuration, numéro de série corrigeable par
-- l'agent ----
create policy carnets_select on carnets for select
  using (app_is_agent(group_id) or app_is_self_member(member_id));
create policy carnets_insert on carnets for insert
  with check (app_is_agent(group_id));
create policy carnets_update on carnets for update
  using (app_is_agent(group_id));

-- ---- amende_paiements : financière en ajout seul (comme
-- pret_remboursements) ----
create policy amende_paiements_select on amende_paiements for select
  using (app_is_agent(app_group_of_amende(amende_id)) or app_is_self_member(app_member_of_amende(amende_id)));
create policy amende_paiements_insert on amende_paiements for insert
  with check (app_is_agent(app_group_of_amende(amende_id)));

-- ---- cotisations_exceptionnelles : financière pour l'événement,
-- mais motif/montant/date limite restent modifiables ensuite (voir
-- AppDatabase.modifierCotisationExceptionnelle) — jamais les
-- paiements réels contre elle, qui vivent dans
-- fonds_solidarite_contributions, déjà en ajout seul ----
create policy cotisations_exceptionnelles_select on cotisations_exceptionnelles for select
  using (app_is_agent(group_id) or exists (
    select 1 from members m where m.group_id = cotisations_exceptionnelles.group_id and m.phone_number = app_current_phone()
  ));
create policy cotisations_exceptionnelles_insert on cotisations_exceptionnelles for insert
  with check (app_is_agent(group_id));
create policy cotisations_exceptionnelles_update on cotisations_exceptionnelles for update
  using (app_is_agent(group_id));

-- ---- pret_demandes / pret_demande_refus : financières en ajout
-- seul (comme pret_demandes/pret_annulations) — toujours saisies par
-- l'agent, comme le reste des écrans Cotisations/Prêts ----
create policy pret_demandes_select on pret_demandes for select
  using (app_is_agent(group_id) or app_is_self_member(member_id));
create policy pret_demandes_insert on pret_demandes for insert
  with check (app_is_agent(group_id));

create policy pret_demande_refus_select on pret_demande_refus for select
  using (app_is_agent(app_group_of_demande(demande_id)) or app_is_self_member(app_member_of_demande(demande_id)));
create policy pret_demande_refus_insert on pret_demande_refus for insert
  with check (app_is_agent(app_group_of_demande(demande_id)));

-- ---- presence_anticipee : brouillon, librement réécrit tant que la
-- journée n'est pas clôturée (voir
-- AppDatabase.marquerPresenceAnticipee/effacerPresenceAnticipee —
-- toujours delete puis insert, jamais d'update) ----
create policy presence_anticipee_select on presence_anticipee for select
  using (app_is_agent(group_id) or app_is_self_member(member_id));
create policy presence_anticipee_insert on presence_anticipee for insert
  with check (app_is_agent(group_id));
create policy presence_anticipee_delete on presence_anticipee for delete
  using (app_is_agent(group_id));
