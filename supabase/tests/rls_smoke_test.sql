-- CotisApp — test de fumée des politiques RLS
--
-- 4 blocs INDÉPENDANTS. Copiez-collez-en UN SEUL à la fois dans l'éditeur
-- SQL Supabase, cliquez Run, notez le résultat, effacez tout, passez au
-- suivant. Chaque bloc insère ses propres données de test puis les
-- annule (`rollback`) — aucune trace ne reste dans la base après coup,
-- et les blocs n'interfèrent pas entre eux.

-- ============================================================
-- BLOC 1 — vu par Membre A. Attendu : 1 ligne, total_parts = 3
-- ============================================================
begin;

insert into groups (id, name) values
  ('00000000-0000-0000-0000-000000000001', 'Groupe test RLS');
insert into members (id, group_id, full_name, phone_number) values
  ('00000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000001', 'Membre A', '+2250700000001'),
  ('00000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000001', 'Membre B', '+2250700000002');
insert into agent_assignments (id, group_id, phone_number, role, hash) values
  ('00000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000001', '+2250700000099', 'agent', 'test-hash');
insert into cycles (id, group_id, cycle_number, part_value_fcfa, interest_rate_percent) values
  ('00000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000001', 1, 1000, 10);
insert into cotisations (id, group_id, cycle_id, member_id, parts_count, recorded_by_phone, hash) values
  ('00000000-0000-0000-0000-000000000041', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000011', 3, '+2250700000099', 'hash-a'),
  ('00000000-0000-0000-0000-000000000042', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000012', 2, '+2250700000099', 'hash-b');

create or replace function app_current_phone() returns text language sql stable as $$ select '+2250700000001'::text $$;
set local role authenticated;
select 'Membre A' as qui, count(*) as lignes, coalesce(sum(parts_count), 0) as total_parts
from cotisations where group_id = '00000000-0000-0000-0000-000000000001';
reset role;

create or replace function app_current_phone()
returns text language sql stable security definer set search_path = public
as $$ select phone from auth.users where id = auth.uid(); $$;

rollback;

-- ============================================================
-- BLOC 2 — vu par Membre B. Attendu : 1 ligne, total_parts = 2
-- (Effacez tout ci-dessus avant de coller ce bloc)
-- ============================================================
begin;

insert into groups (id, name) values
  ('00000000-0000-0000-0000-000000000001', 'Groupe test RLS');
insert into members (id, group_id, full_name, phone_number) values
  ('00000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000001', 'Membre A', '+2250700000001'),
  ('00000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000001', 'Membre B', '+2250700000002');
insert into agent_assignments (id, group_id, phone_number, role, hash) values
  ('00000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000001', '+2250700000099', 'agent', 'test-hash');
insert into cycles (id, group_id, cycle_number, part_value_fcfa, interest_rate_percent) values
  ('00000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000001', 1, 1000, 10);
insert into cotisations (id, group_id, cycle_id, member_id, parts_count, recorded_by_phone, hash) values
  ('00000000-0000-0000-0000-000000000041', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000011', 3, '+2250700000099', 'hash-a'),
  ('00000000-0000-0000-0000-000000000042', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000012', 2, '+2250700000099', 'hash-b');

create or replace function app_current_phone() returns text language sql stable as $$ select '+2250700000002'::text $$;
set local role authenticated;
select 'Membre B' as qui, count(*) as lignes, coalesce(sum(parts_count), 0) as total_parts
from cotisations where group_id = '00000000-0000-0000-0000-000000000001';
reset role;

create or replace function app_current_phone()
returns text language sql stable security definer set search_path = public
as $$ select phone from auth.users where id = auth.uid(); $$;

rollback;

-- ============================================================
-- BLOC 3 — vu par l'agent du groupe. Attendu : 2 lignes, total_parts = 5
-- (Effacez tout ci-dessus avant de coller ce bloc)
-- ============================================================
begin;

insert into groups (id, name) values
  ('00000000-0000-0000-0000-000000000001', 'Groupe test RLS');
insert into members (id, group_id, full_name, phone_number) values
  ('00000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000001', 'Membre A', '+2250700000001'),
  ('00000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000001', 'Membre B', '+2250700000002');
insert into agent_assignments (id, group_id, phone_number, role, hash) values
  ('00000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000001', '+2250700000099', 'agent', 'test-hash');
insert into cycles (id, group_id, cycle_number, part_value_fcfa, interest_rate_percent) values
  ('00000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000001', 1, 1000, 10);
insert into cotisations (id, group_id, cycle_id, member_id, parts_count, recorded_by_phone, hash) values
  ('00000000-0000-0000-0000-000000000041', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000011', 3, '+2250700000099', 'hash-a'),
  ('00000000-0000-0000-0000-000000000042', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000012', 2, '+2250700000099', 'hash-b');

create or replace function app_current_phone() returns text language sql stable as $$ select '+2250700000099'::text $$;
set local role authenticated;
select 'Agent' as qui, count(*) as lignes, coalesce(sum(parts_count), 0) as total_parts
from cotisations where group_id = '00000000-0000-0000-0000-000000000001';
reset role;

create or replace function app_current_phone()
returns text language sql stable security definer set search_path = public
as $$ select phone from auth.users where id = auth.uid(); $$;

rollback;

-- ============================================================
-- BLOC 4 — vu par un numéro inconnu, sans lien avec le groupe.
-- Attendu : 0 ligne (déjà vérifié une fois, gardé pour mémoire)
-- ============================================================
