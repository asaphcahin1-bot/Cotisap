-- CotisApp — refonte carnet/part + clôture de journée de cotisation
--
-- Miroir de la migration drift schemaVersion 6 -> 7
-- (lib/data/local/database.dart). À coller dans le SQL Editor Supabase
-- APRÈS 0001_init.sql, 0002_membres_sans_telephone.sql et
-- 0003_echeances_et_partage.sql.
--
-- Voir DECISIONS.md : "Carnets : 1 ou 2 par membre", "Parts libres par
-- cotisation, minimum 1", "Clôture de la journée de cotisation", "Un
-- membre ajouté en cours de cycle ne doit rien avant son entrée".
--
-- ATTENTION — dette technique constatée en écrivant ce fichier :
-- `carnets_engages` n'avait jamais été créée côté Postgres (ajoutée en
-- drift à schemaVersion 4, jamais mirée) ; `groups.payment_day_of_week`
-- / `payment_day_of_month1/2`, `cycles.loan_duration_days`,
-- `amendes.est_auto_generee`/`confirmed_at`, `amende_annulations`
-- (schemaVersion 4-5) manquent aussi côté Postgres. Sans conséquence
-- tant que la synchronisation reste inactive (voir ROADMAP.md, étape
-- 3, bloquée par l'authentification Twilio) mais **à combler avant de
-- brancher la synchronisation réelle**, pas avant. Ce fichier crée
-- `carnets_engages` directement avec sa structure actuelle
-- (`nombre_carnets`) plutôt que de rejouer son historique.

create table if not exists carnets_engages (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id),
  cycle_id uuid not null references cycles(id),
  member_id uuid not null references members(id),
  nombre_carnets integer not null check (nombre_carnets in (1, 2)),
  locked_at timestamptz,
  unique (cycle_id, member_id)
);

alter table cotisations
  add column if not exists carnet_numero integer not null default 1 check (carnet_numero in (1, 2));

alter table echeances
  add column if not exists carnet_numero integer not null default 1 check (carnet_numero in (1, 2));

-- L'ancienne colonne carnets_engages (multiplicateur) sur echeances n'a
-- jamais existé côté Postgres (schemaVersion 6 jamais miré) — rien à
-- retirer ici.

alter table cycles
  add column if not exists inscriptions_fermees_at timestamptz;

create table if not exists seances_cotisation (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id),
  cycle_id uuid not null references cycles(id),
  date timestamptz not null,
  cloturee_par_phone text not null,
  cloturee_at timestamptz not null default now(),
  previous_hash text,
  hash text not null,
  unique (cycle_id, date)
);

create index if not exists idx_carnets_engages_cycle on carnets_engages(cycle_id);
create index if not exists idx_seances_cotisation_cycle on seances_cotisation(cycle_id);

alter table carnets_engages enable row level security;
alter table seances_cotisation enable row level security;

-- ---- carnets_engages : pas une table financière en ajout seul (voir
-- CarnetsEngages en drift) — update autorisé tant que non verrouillée,
-- appliqué côté application (locked_at), pas re-vérifié ici par une
-- policy dédiée pour rester simple à ce stade.
create policy carnets_engages_select on carnets_engages for select
  using (app_is_agent(group_id) or app_is_self_member(member_id));
create policy carnets_engages_insert on carnets_engages for insert
  with check (app_is_agent(group_id));
create policy carnets_engages_update on carnets_engages for update
  using (app_is_agent(group_id));

create policy seances_cotisation_select on seances_cotisation for select
  using (app_is_agent(group_id) or exists (
    select 1 from members m where m.group_id = seances_cotisation.group_id and m.phone_number = app_current_phone()
  ));
create policy seances_cotisation_insert on seances_cotisation for insert
  with check (app_is_agent(group_id));
