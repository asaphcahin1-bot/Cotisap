import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting.dart';
import '../../data/local/database.dart';
import '../../state/providers.dart';

/// Historique des cotisations groupé par date d'échéance — demande du
/// fondateur ("Historique des cotisations") : au lieu d'une liste plate
/// d'enregistrements, chaque date de séance devient un groupe dépliable
/// listant chaque membre et son statut (Payé / Non payé-Absent).
///
/// Construit à partir du registre [AppDatabase.echeancesGroupeesParDate]
/// plutôt que de la table `cotisations` directement : c'est ce registre
/// qui trace aussi les échéances manquées sans paiement associé (voir
/// DECISIONS.md).
class CotisationsHistoryScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String cycleId;

  const CotisationsHistoryScreen({
    super.key,
    required this.groupId,
    required this.cycleId,
  });

  @override
  ConsumerState<CotisationsHistoryScreen> createState() =>
      _CotisationsHistoryScreenState();
}

class _HistoryData {
  final List<EcheanceGroupeeParDate> groupes;
  final Map<String, Member> membresParId;
  final Map<String, String> statutsAmendes;

  const _HistoryData({
    required this.groupes,
    required this.membresParId,
    required this.statutsAmendes,
  });
}

/// Vrai si au moins une ligne de ce groupe porte une amende encore
/// `en_attente` — sert à afficher une étoile rouge devant la date (et
/// le mois) pour repérer en un coup d'œil les journées qui ont encore
/// une amende à régler, sans avoir à déplier chaque séance (demande du
/// fondateur, voir DECISIONS.md).
bool _aUneAmendeEnAttente(
  EcheanceGroupeeParDate groupe,
  Map<String, String> statutsAmendes,
) {
  return groupe.lignes.any(
    (l) => l.amendeId != null && statutsAmendes[l.amendeId] == 'en_attente',
  );
}

/// Libellé + couleur d'un statut d'amende (voir
/// [AppDatabase.statutsAmendes] — "reglee"/"en_attente"/"annulee").
(String, Color) _libelleStatutAmende(String statut, BuildContext context) {
  switch (statut) {
    case 'reglee':
      return ('réglée', Colors.green);
    case 'annulee':
      return ('annulée — erreur', Colors.grey);
    default:
      return ('en attente', Theme.of(context).colorScheme.error);
  }
}

class _CotisationsHistoryScreenState
    extends ConsumerState<CotisationsHistoryScreen> {
  late Future<_HistoryData> _dataFuture;

  @override
  void initState() {
    super.initState();
    final db = ref.read(databaseProvider);
    _dataFuture = _fetch(db);
  }

  Future<_HistoryData> _fetch(AppDatabase db) async {
    final groupes = await db.echeancesGroupeesParDate(widget.cycleId);
    final membres = await db.membresDuGroupe(widget.groupId);
    final statuts = await db.statutsAmendes(widget.cycleId);
    return _HistoryData(
      groupes: groupes,
      membresParId: {for (final m in membres) m.id: m},
      statutsAmendes: statuts,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique des épargnes')),
      body: FutureBuilder<_HistoryData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          if (data.groupes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucune échéance close pour le moment — l\'historique se '
                  'remplit au fil des séances.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // Regroupé par mois (le plus récent d'abord, [data.groupes] est
          // déjà trié dans cet ordre) — un cycle qui s'étend sur
          // plusieurs mois donnerait sinon une liste de dates sans fin à
          // faire défiler pour retrouver une séance précise.
          final moisOrdonnes = <DateTime>[];
          final groupesParMois = <DateTime, List<EcheanceGroupeeParDate>>{};
          for (final groupe in data.groupes) {
            final cleMois = DateTime(groupe.date.year, groupe.date.month);
            if (!groupesParMois.containsKey(cleMois)) {
              groupesParMois[cleMois] = [];
              moisOrdonnes.add(cleMois);
            }
            groupesParMois[cleMois]!.add(groupe);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: moisOrdonnes.length,
            itemBuilder: (context, moisIndex) {
              final cleMois = moisOrdonnes[moisIndex];
              final groupesDuMois = groupesParMois[cleMois]!;
              final payesDuMois = groupesDuMois.fold<int>(
                0,
                (s, g) => s + g.lignes.where((l) => l.statut == 'paye').length,
              );
              final totalDuMois = groupesDuMois.fold<int>(
                0,
                (s, g) => s + g.lignes.length,
              );
              final moisAUneAmendeEnAttente = groupesDuMois.any(
                (g) => _aUneAmendeEnAttente(g, data.statutsAmendes),
              );
              return ExpansionTile(
                // Seul le mois le plus récent est déplié par défaut — les
                // mois précédents restent consultables en un clic sans
                // encombrer l'écran.
                initiallyExpanded: moisIndex == 0,
                title: Row(
                  children: [
                    if (moisAUneAmendeEnAttente) ...[
                      const Text('★', style: TextStyle(color: Colors.red)),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      formatMoisAnneeFr(cleMois),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                subtitle: Text(
                  '${groupesDuMois.length} séance(s) — $payesDuMois payé(s) / '
                  '${totalDuMois - payesDuMois} non payé(s)',
                ),
                children: groupesDuMois.map((groupe) {
                  final payes = groupe.lignes
                      .where((l) => l.statut == 'paye')
                      .length;
                  final dateAUneAmendeEnAttente = _aUneAmendeEnAttente(
                    groupe,
                    data.statutsAmendes,
                  );
                  return ExpansionTile(
                    title: Row(
                      children: [
                        if (dateAUneAmendeEnAttente) ...[
                          const Text('★', style: TextStyle(color: Colors.red)),
                          const SizedBox(width: 6),
                        ],
                        Text(formatDateFr(groupe.date)),
                      ],
                    ),
                    subtitle: Text(
                      '$payes payé(s) / ${groupe.lignes.length - payes} non payé(s)',
                    ),
                    children: groupe.lignes.map((ligne) {
                      final nom =
                          data.membresParId[ligne.memberId]?.fullName ??
                          ligne.memberId;
                      final paye = ligne.statut == 'paye';
                      final statutAmende = ligne.amendeId != null
                          ? data.statutsAmendes[ligne.amendeId]
                          : null;
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          paye ? Icons.check_circle : Icons.cancel_outlined,
                          color: paye
                              ? Colors.green
                              : Theme.of(context).colorScheme.error,
                        ),
                        title: Text('$nom — carnet ${ligne.carnetNumero}'),
                        subtitle: Text(
                          paye
                              ? '${ligne.partsPayees} part(s) — ${formatFcfa(ligne.montantPayeFcfa)}'
                                    '${ligne.amendeFcfa > 0 ? ' (dont ${formatFcfa(ligne.amendeFcfa)} amende)' : ''}'
                              : 'Non payé / Absent'
                                    '${ligne.amendeFcfa > 0 ? ' — amende ${formatFcfa(ligne.amendeFcfa)}' : ''}',
                        ),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              paye ? 'Payé' : 'Non payé',
                              style: TextStyle(
                                color: paye
                                    ? Colors.green
                                    : Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (statutAmende != null)
                              Builder(
                                builder: (context) {
                                  final (
                                    libelle,
                                    couleur,
                                  ) = _libelleStatutAmende(
                                    statutAmende,
                                    context,
                                  );
                                  return Text(
                                    'Amende : $libelle',
                                    style: TextStyle(
                                      color: couleur,
                                      fontSize: 11,
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
