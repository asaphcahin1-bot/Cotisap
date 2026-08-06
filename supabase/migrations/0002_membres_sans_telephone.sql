-- CotisApp — membres sans téléphone + confirmation de prêt par signature
--
-- Miroir de la migration drift schemaVersion 2 -> 3
-- (lib/data/local/database.dart). À coller dans le SQL Editor Supabase
-- APRÈS 0001_init.sql.

-- Un membre peut ne pas avoir de téléphone personnel (skill
-- member-consent-rules, "cas des membres sans smartphone").
alter table members alter column phone_number drop not null;

-- Un prêt destiné à un membre sans téléphone n'a pas de code à envoyer.
alter table prets alter column confirmation_code drop not null;

-- Deux méthodes de confirmation, jamais mélangées sur une même ligne :
-- 'code' (SMS, comme avant) ou 'signature' (membre sans téléphone,
-- capturée en personne par l'agent témoin).
alter table pret_confirmations
  add column if not exists methode text not null default 'code'
    check (methode in ('code', 'signature')),
  add column if not exists witness_phone text,
  add column if not exists signature_data text;

alter table pret_confirmations alter column code_saisi drop not null;
alter table pret_confirmations alter column confirmed_by_phone drop not null;

-- ============================================================
-- Politique RLS mise à jour pour pret_confirmations_insert
-- ============================================================
-- L'ancienne politique n'autorisait que la méthode 'code' (le membre
-- confirme lui-même). On ajoute la méthode 'signature', réservée à
-- l'agent du groupe témoin ET uniquement si le membre concerné n'a
-- effectivement aucun téléphone enregistré — jamais un raccourci pour
-- contourner la confirmation SMS d'un membre qui en a un.

drop policy if exists pret_confirmations_insert on pret_confirmations;

create policy pret_confirmations_insert on pret_confirmations for insert
  with check (
    (
      methode = 'code'
      and confirmed_by_phone = app_current_phone()
      and app_is_self_member(app_member_of_pret(pret_id))
    )
    or (
      methode = 'signature'
      and witness_phone = app_current_phone()
      and app_is_agent(app_group_of_pret(pret_id))
      and not exists (
        select 1 from members m
        where m.id = app_member_of_pret(pret_id)
          and m.phone_number is not null
      )
    )
  );
