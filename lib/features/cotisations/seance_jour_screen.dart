import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting.dart';
import '../../data/local/database.dart';
import '../../state/providers.dart';

/// Écran "Séance du jour" — voir RETOURS_TERRAIN.md, point 20 : vue
/// d'ensemble de la journée de cotisation ouverte, **en lecture
/// seule**. Toutes les actions (cotisation, présence, crédit, amende)
/// se font désormais sur l'écran Cotisation
/// (`cotisation_membre_screen.dart`) — cet écran-ci ne fait que
/// résumer, membre par membre, ce qui a déjà été enregistré aujourd'hui.
class SeanceJourScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String cycleId;

  const SeanceJourScreen({
    super.key,
    required this.groupId,
    required this.cycleId,
  });

  @override
  ConsumerState<SeanceJourScreen> createState() => _SeanceJourScreenState();
}

class _SeanceJourScreenState extends ConsumerState<SeanceJourScreen> {
  late Future<_SeanceJourData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final db = ref.read(databaseProvider);
    setState(() {
      _dataFuture = _fetch(db);
    });
  }

  Future<_SeanceJourData> _fetch(AppDatabase db) async {
    // Filet de sécurité 23h (voir RETOURS_TERRAIN.md) — même mécanisme
    // que record_cotisation_screen.dart.
    final journeeOuverte =
        await db.journeeCotisationEnAttenteEtAutoClotureSiDepassee(
          groupId: widget.groupId,
          cycleId: widget.cycleId,
          agentPhone: ref.read(currentPhoneNumberProvider) ?? 'inconnu',
        );
    final membres = await db.membresDuGroupe(widget.groupId);
    final statuts = <String, _StatutMembre>{};
    if (journeeOuverte != null) {
      final anticipees = await db.presenceAnticipeeDuJour(
        cycleId: widget.cycleId,
        date: journeeOuverte,
      );
      for (final m in membres) {
        if (m.joinedAt.isAfter(journeeOuverte)) {
          statuts[m.id] = _StatutMembre.pasEncoreMembre;
          continue;
        }
        final carnets = await db.carnetsEngagesDuMembre(
          memberId: m.id,
          cycleId: widget.cycleId,
        );
        if (carnets == null) {
          statuts[m.id] = _StatutMembre.carnetsNonDefinis;
          continue;
        }
        var aTraiter = false;
        var anticipeAbsent = false;
        for (
          var carnetNumero = 1;
          carnetNumero <= carnets.nombreCarnets;
          carnetNumero++
        ) {
          final motifs = await db.motifsSystemeApplicables(
            memberId: m.id,
            cycleId: widget.cycleId,
            carnetNumero: carnetNumero,
            echeanceDate: journeeOuverte,
          );
          if (motifs.isEmpty) continue; // déjà réglé (payé ou amende posée)
          aTraiter = true;
          if (anticipees.containsKey(
            AppDatabase.clefResolutionCarnet(m.id, carnetNumero),
          )) {
            anticipeAbsent = true;
          }
        }
        statuts[m.id] = !aTraiter
            ? _StatutMembre.regle
            : anticipeAbsent
            ? _StatutMembre.absentAnticipe
            : _StatutMembre.aTraiter;
      }
    }
    return _SeanceJourData(
      journeeOuverte: journeeOuverte,
      membres: membres,
      statuts: statuts,
    );
  }

  Future<void> _openRecap(Member membre, DateTime date) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MemberRecapSheet(
        groupId: widget.groupId,
        cycleId: widget.cycleId,
        membre: membre,
        date: date,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Séance du jour')),
      body: FutureBuilder<_SeanceJourData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          if (data.journeeOuverte == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucune journée d\'épargne ouverte pour le moment — la '
                  'prochaine réunion ne sera possible qu\'à la date de la '
                  'prochaine échéance programmée.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final date = data.journeeOuverte!;
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Réunion du ${date.day}/${date.month}/${date.year} — '
                  'touchez un membre pour voir le récap de la journée. Pour '
                  'agir (épargne, présence, crédit, amende), utilisez '
                  'l\'écran Épargne.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const Divider(height: 1),
              for (final m in data.membres)
                if (data.statuts[m.id] != _StatutMembre.pasEncoreMembre)
                  ListTile(
                    title: Text(m.fullName),
                    subtitle: _statutLabel(data.statuts[m.id]),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openRecap(m, date),
                  ),
            ],
          );
        },
      ),
    );
  }

  Widget? _statutLabel(_StatutMembre? statut) {
    switch (statut) {
      case _StatutMembre.regle:
        return const Text(
          'Réglé aujourd\'hui',
          style: TextStyle(color: Colors.green),
        );
      case _StatutMembre.absentAnticipe:
        return Text(
          'Absent (à confirmer à la clôture)',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        );
      case _StatutMembre.aTraiter:
        return const Text(
          'À traiter',
          style: TextStyle(fontStyle: FontStyle.italic),
        );
      case _StatutMembre.carnetsNonDefinis:
        return const Text(
          'Carnets non définis',
          style: TextStyle(fontStyle: FontStyle.italic),
        );
      case _StatutMembre.pasEncoreMembre:
      case null:
        return null;
    }
  }
}

enum _StatutMembre {
  regle,
  aTraiter,
  absentAnticipe,
  carnetsNonDefinis,
  pasEncoreMembre,
}

class _SeanceJourData {
  final DateTime? journeeOuverte;
  final List<Member> membres;
  final Map<String, _StatutMembre> statuts;

  const _SeanceJourData({
    required this.journeeOuverte,
    required this.membres,
    required this.statuts,
  });
}

/// Récap en lecture seule de ce qui a été enregistré aujourd'hui pour
/// un membre — voir la doc de [SeanceJourScreen] : parts déjà
/// achetées par carnet, amende reçue, remboursement de prêt versé,
/// présence. Aucune action possible ici.
class _MemberRecapSheet extends ConsumerStatefulWidget {
  final String groupId;
  final String cycleId;
  final Member membre;
  final DateTime date;

  const _MemberRecapSheet({
    required this.groupId,
    required this.cycleId,
    required this.membre,
    required this.date,
  });

  @override
  ConsumerState<_MemberRecapSheet> createState() => _MemberRecapSheetState();
}

class _MemberRecapSheetState extends ConsumerState<_MemberRecapSheet> {
  late Future<_RecapData> _dataFuture;

  @override
  void initState() {
    super.initState();
    final db = ref.read(databaseProvider);
    _dataFuture = _fetch(db);
  }

  Future<_RecapData> _fetch(AppDatabase db) async {
    final echeances = (await db.echeancesResoluesPourDate(
      cycleId: widget.cycleId,
      date: widget.date,
    )).where((e) => e.memberId == widget.membre.id).toList()
      ..sort((a, b) => a.carnetNumero.compareTo(b.carnetNumero));

    final anticipees = await db.presenceAnticipeeDuJour(
      cycleId: widget.cycleId,
      date: widget.date,
    );
    final anticipeePourCeMembre = <int, String>{
      for (final e in anticipees.entries)
        if (e.key.startsWith('${widget.membre.id}::'))
          int.parse(e.key.split('::').last): e.value,
    };

    final rembourseAuJour = await db.totalRembourseParMembreAuJour(
      memberId: widget.membre.id,
      cycleId: widget.cycleId,
      jour: widget.date,
    );

    return _RecapData(
      echeances: echeances,
      anticipeePourCeMembre: anticipeePourCeMembre,
      rembourseAuJourFcfa: rembourseAuJour,
    );
  }

  String _libelleMotif(String? code) {
    switch (code) {
      case AppDatabase.codeSystemePartImpayee:
        return 'Part impayée';
      case AppDatabase.codeSystemePayeParTiers:
        return 'Payé par un tiers';
      case AppDatabase.codeSystemeAbsence:
      default:
        return 'Absence';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => FutureBuilder<_RecapData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                widget.membre.fullName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                'Récap du ${widget.date.day}/${widget.date.month}/${widget.date.year} '
                '— lecture seule',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
              const Divider(height: 24),

              if (data.echeances.isEmpty &&
                  data.anticipeePourCeMembre.isEmpty)
                const Text(
                  'Rien enregistré pour ce membre aujourd\'hui pour le moment.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),

              for (final e in data.echeances)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    e.statut == 'paye'
                        ? Icons.check_circle
                        : Icons.cancel_outlined,
                    color: e.statut == 'paye'
                        ? Colors.green
                        : Theme.of(context).colorScheme.error,
                  ),
                  title: Text('Carnet ${e.carnetNumero}'),
                  subtitle: Text(
                    e.statut == 'paye'
                        ? '${e.partsPayees} part(s) — ${formatFcfa(e.montantPayeFcfa)}'
                        : 'Non payé'
                              '${e.amendeFcfa > 0 ? ' — amende ${formatFcfa(e.amendeFcfa)}' : ''}',
                  ),
                ),

              for (final entry in data.anticipeePourCeMembre.entries)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.hourglass_top,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text('Carnet ${entry.key}'),
                  subtitle: Text(
                    '${_libelleMotif(entry.value)} (anticipé — à confirmer '
                    'à la clôture)',
                  ),
                ),

              if (data.rembourseAuJourFcfa > 0) ...[
                const Divider(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.payments_outlined),
                  title: const Text('Remboursement de prêt'),
                  subtitle: Text(formatFcfa(data.rembourseAuJourFcfa)),
                ),
              ],
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}

class _RecapData {
  final List<Echeance> echeances;
  final Map<int, String> anticipeePourCeMembre;
  final int rembourseAuJourFcfa;

  const _RecapData({
    required this.echeances,
    required this.anticipeePourCeMembre,
    required this.rembourseAuJourFcfa,
  });
}
