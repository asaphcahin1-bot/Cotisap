-- CotisApp — suppression du rattrapage + plafond journalier basé sur
-- l'échéance
--
-- Miroir des migrations drift schemaVersion 7 -> 8 -> 9
-- (lib/data/local/database.dart). À coller dans le SQL Editor Supabase
-- APRÈS 0001_init.sql, 0002_membres_sans_telephone.sql,
-- 0003_echeances_et_partage.sql et 0004_carnets_et_seances.sql.
--
-- Voir DECISIONS.md : "Amende seule, jamais de rattrapage", "Le plafond
-- journalier se base sur l'échéance, pas sur l'heure de saisie".
--
-- Comme pour 0004 : aucun groupe réel n'utilise encore la synchronisation
-- Supabase (bloquée en attendant l'authentification Twilio, voir
-- ROADMAP.md), donc pas de rétro-remplissage nécessaire pour les lignes
-- existantes — ces colonnes restent nullable/à zéro pour tout ce qui a
-- été écrit avant.

-- schemaVersion 7 -> 8 : une échéance porte désormais un nombre de
-- parts explicite (le cumul du jour, pas seulement cette transaction)
-- plutôt qu'un simple montant.
alter table echeances
  add column if not exists parts_payees integer;

-- schemaVersion 8 -> 9 : le plafond cumulatif de 5 parts/carnet/jour se
-- base sur la date d'échéance visée par la transaction, pas sur
-- l'horodatage réel/simulé de la saisie (recorded_at) — un agent peut
-- saisir plusieurs transactions pour la même échéance à des instants
-- réels différents, et ne doit jamais mélanger deux échéances
-- différentes saisies le même jour réel.
alter table cotisations
  add column if not exists echeance_date timestamptz;
