import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting.dart';
import '../../data/local/database.dart';
import '../../domain/calculators/echeance_calculator.dart';
import '../../state/providers.dart';
import 'amende_fonds_dialogs.dart';
import 'cotisation_membre_screen.dart';
import 'cotisations_history_screen.dart';
import 'seance_jour_screen.dart';

class RecordCotisationScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String cycleId;

  const RecordCotisationScreen({
    super.key,
    required this.groupId,
    required this.cycleId,
  });

  @override
  ConsumerState<RecordCotisationScreen> createState() =>
      _RecordCotisationScreenState();
}

class _RecordCotisationScreenState
    extends ConsumerState<RecordCotisationScreen> {
  late Future<List<Member>> _membersFuture;
  late Future<DateTime?> _journeeOuverteFuture;
  late Future<List<MotifsAmendeData>> _motifsActifsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final db = ref.read(databaseProvider);
    setState(() {
      _membersFuture = db.membresDuGroupe(widget.groupId);
      // Filet de sécurité 23h (voir RETOURS_TERRAIN.md) : rattrape et
      // clôture automatiquement toute journée restée bloquée, avant de
      // renvoyer la vraie journée encore ouverte.
      _journeeOuverteFuture = db.journeeCotisationEnAttenteEtAutoClotureSiDepassee(
        groupId: widget.groupId,
        cycleId: widget.cycleId,
        agentPhone: ref.read(currentPhoneNumberProvider) ?? 'inconnu',
      );
      _motifsActifsFuture = db.motifsAmendeActifsDuGroupe(widget.groupId);
    });
  }

  /// Ouvre l'écran Cotisation pour ce membre — voir
  /// `cotisation_membre_screen.dart` : cotisation, présence, et toutes
  /// les autres actions (amende, cotisation exceptionnelle, fonds de
  /// solidarité, prêt) au même endroit, avec possibilité d'enchaîner
  /// sur le membre suivant sans ressortir de l'écran.
  Future<void> _ouvrirEcranCotisation(List<Member> membres, String memberId) async {
    final index = membres.indexWhere((m) => m.id == memberId);
    if (index == -1) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CotisationMembreScreen(
          groupId: widget.groupId,
          cycleId: widget.cycleId,
          membres: membres,
          initialIndex: index,
        ),
      ),
    );
    _reload();
  }

  Future<void> _openAddAmendeDialog() async {
    final membres = await _membersFuture;
    final motifs = await _motifsActifsFuture;
    if (!mounted) return;
    final db = ref.read(databaseProvider);
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
    await showAddAmendeDialog(
      context: context,
      db: db,
      groupId: widget.groupId,
      cycleId: widget.cycleId,
      agentPhone: agentPhone,
      membres: membres,
      motifsCatalogue: motifs,
      onSaved: _reload,
    );
  }

  Future<void> _openAddFondsDialog() async {
    final membres = await _membersFuture;
    if (!mounted) return;
    final db = ref.read(databaseProvider);
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
    await showAddFondsDialog(
      context: context,
      db: db,
      groupId: widget.groupId,
      cycleId: widget.cycleId,
      agentPhone: agentPhone,
      membres: membres,
      onSaved: _reload,
    );
  }

  /// Avant de clôturer réellement, l'agent résout chaque carnet sans
  /// rien d'enregistré (ni cotisation, ni amende) — un motif parmi les
  /// 3 prédéfinis (Absence / Part impayée / Payé par un tiers), choisi
  /// **le jour même**, jamais différé à la séance suivante (voir
  /// DECISIONS.md, "Clôture de journée interactive" — remplace
  /// entièrement l'ancienne revue différée).
  ///
  /// **Aucun motif pré-sélectionné par défaut** (revu le 2026-08-14,
  /// annule le repli automatique sur "Absence" décrit à l'origine dans
  /// DECISIONS.md) : le fondateur a explicitement demandé qu'aucune
  /// amende ne puisse jamais s'appliquer sans un choix actif de l'agent,
  /// carnet par carnet — "Clôturer définitivement" reste désactivé tant
  /// qu'il en manque un. Seule exception, qui reste un choix explicite
  /// et non un défaut caché : un carnet déjà anticipé plus tôt dans la
  /// journée (écran "Séance du jour", voir RETOURS_TERRAIN.md, point 6)
  /// reste pré-rempli avec ce choix-là.
  Future<void> _cloturerJournee(DateTime date) async {
    final db = ref.read(databaseProvider);
    final aTraiter = await db.carnetsATraiterPourDate(
      groupId: widget.groupId,
      cycleId: widget.cycleId,
      date: date,
    );
    if (!mounted) return;

    final anticipees = await db.presenceAnticipeeDuJour(
      cycleId: widget.cycleId,
      date: date,
    );
    if (!mounted) return;
    // `null` = pas encore choisi par l'agent — jamais de repli
    // automatique sur "Absence".
    final resolutions = <String, String?>{
      for (final r in aTraiter)
        AppDatabase.clefResolutionCarnet(r.membre.id, r.carnetNumero):
            anticipees[AppDatabase.clefResolutionCarnet(
              r.membre.id,
              r.carnetNumero,
            )],
    };
    const libellesMotifs = {
      AppDatabase.codeSystemeAbsence: 'Absence',
      AppDatabase.codeSystemePartImpayee: 'Part impayée',
      AppDatabase.codeSystemePayeParTiers: 'Payé par un tiers',
    };

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final tousResolus = aTraiter.every(
            (r) =>
                resolutions[AppDatabase.clefResolutionCarnet(
                  r.membre.id,
                  r.carnetNumero,
                )] !=
                null,
          );
          return AlertDialog(
            title: Text(
              'La réunion est terminée — clôturer le '
              '${date.day}/${date.month}/${date.year} ?',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (aTraiter.isEmpty)
                    const Text(
                      'Tous les membres figurent sur la liste définitive du jour.',
                    )
                  else ...[
                    Text(
                      '${aTraiter.length} carnet(s) sans rien d\'enregistré — '
                      'précisez pourquoi avant de clôturer (obligatoire pour '
                      'chacun) :',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    ...aTraiter.map((r) {
                      final cle = AppDatabase.clefResolutionCarnet(
                        r.membre.id,
                        r.carnetNumero,
                      );
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${r.membre.fullName} — carnet ${r.carnetNumero}',
                              ),
                            ),
                            DropdownButton<String>(
                              value: resolutions[cle],
                              hint: const Text('Choisir…'),
                              items: [
                                for (final code in r.motifsPossibles)
                                  DropdownMenuItem(
                                    value: code,
                                    child: Text(libellesMotifs[code] ?? code),
                                  ),
                              ],
                              onChanged: (v) =>
                                  setDialogState(() => resolutions[cle] = v),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (!tousResolus) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Choisissez un motif pour chaque carnet listé ci-dessus.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'Définitif : cette date ne pourra plus recevoir de nouvel '
                    'encaissement une fois clôturée, et il ne sera plus possible '
                    'de revenir en arrière.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Revoir'),
              ),
              FilledButton(
                onPressed: tousResolus
                    ? () => Navigator.of(context).pop(true)
                    : null,
                child: const Text('Clôturer définitivement'),
              ),
            ],
          );
        },
      ),
    );
    if (confirme != true) return;
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
    await db.cloturerJourneeCotisation(
      groupId: widget.groupId,
      cycleId: widget.cycleId,
      date: date,
      agentPhone: agentPhone,
      // Sûr : le bouton n'était activable que si `tousResolus` — chaque
      // valeur est garantie non nulle ici.
      resolutions: resolutions.map((k, v) => MapEntry(k, v!)),
    );
    if (!mounted) return;

    // Annonce la date de la prochaine réunion dans le message de
    // confirmation — plus pratique que de laisser l'agent le déduire
    // lui-même (demande du fondateur, voir DECISIONS.md).
    final groupe = await (db.select(
      db.groups,
    )..where((g) => g.id.equals(widget.groupId))).getSingle();
    final prochaine = const EcheanceCalculator().prochaineEcheance(
      apres: date,
      meetingFrequency: groupe.meetingFrequency,
      paymentDayOfWeek: groupe.paymentDayOfWeek,
      paymentDayOfMonth1: groupe.paymentDayOfMonth1,
      paymentDayOfMonth2: groupe.paymentDayOfMonth2,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Journée du ${formatDateFr(date)} clôturée — prochaine réunion : '
          '${formatDateFr(prochaine)}.',
        ),
        duration: const Duration(seconds: 6),
      ),
    );
    _reload();
  }

  Widget _ligneEcheance(Echeance ligne, Map<String, Member> membresParId) {
    final nom = membresParId[ligne.memberId]?.fullName ?? ligne.memberId;
    final paye = ligne.statut == 'paye';
    final heure =
        '${ligne.recordedAt.hour.toString().padLeft(2, '0')}h${ligne.recordedAt.minute.toString().padLeft(2, '0')}';
    return ListTile(
      dense: true,
      leading: Icon(
        paye ? Icons.check_circle : Icons.cancel_outlined,
        color: paye ? Colors.green : Theme.of(context).colorScheme.error,
      ),
      title: Text('$nom — carnet ${ligne.carnetNumero}'),
      subtitle: Text(
        paye
            ? '${ligne.partsPayees} part(s) — ${formatFcfa(ligne.montantPayeFcfa)}'
                  ' · $heure · ${ligne.recordedByPhone}'
            : 'Non payé / Absent'
                  '${ligne.amendeFcfa > 0 ? ' — amende ${formatFcfa(ligne.amendeFcfa)}' : ''}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Épargnes (cash)'),
        actions: [
          // Accessibles directement pendant la saisie des encaissements —
          // pas seulement depuis l'écran Répartition (voir DECISIONS.md,
          // "Écran Cotisations moins chargé") — en actions compactes pour
          // ne pas alourdir cet écran.
          IconButton(
            icon: const Icon(Icons.groups_outlined),
            tooltip: 'Séance du jour — vue d\'ensemble (lecture seule)',
            onPressed: () => Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (_) => SeanceJourScreen(
                      groupId: widget.groupId,
                      cycleId: widget.cycleId,
                    ),
                  ),
                )
                .then((_) => _reload()),
          ),
          IconButton(
            icon: const Icon(Icons.report_gmailerrorred_outlined),
            tooltip: 'Ajouter une amende',
            onPressed: _openAddAmendeDialog,
          ),
          IconButton(
            icon: const Icon(Icons.volunteer_activism_outlined),
            tooltip: 'Contribution fonds',
            onPressed: _openAddFondsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historique par date',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CotisationsHistoryScreen(
                  groupId: widget.groupId,
                  cycleId: widget.cycleId,
                ),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Member>>(
        future: _membersFuture,
        builder: (context, memberSnapshot) {
          if (!memberSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final membres = memberSnapshot.data!;
          final membresParId = {for (final m in membres) m.id: m};

          return ListView(
            children: [
              // Clôture de journée en attente — jamais automatique/silencieuse,
              // toujours un rappel visible tant que l'agent n'a pas tranché
              // (voir DECISIONS.md, "Clôture de la journée de cotisation").
              FutureBuilder<DateTime?>(
                future: _journeeOuverteFuture,
                builder: (context, snapshot) {
                  final date = snapshot.data;
                  if (date == null) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Journée du ${date.day}/${date.month}/${date.year} en cours',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tant que cette journée n\'est pas clôturée, les membres '
                          'peuvent encore compléter leur paiement. Les membres '
                          'absents ne sont marqués en retard qu\'à la clôture.',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (_) => SeanceJourScreen(
                                    groupId: widget.groupId,
                                    cycleId: widget.cycleId,
                                  ),
                                ),
                              )
                              .then((_) => _reload()),
                          icon: const Icon(Icons.groups_outlined),
                          label: const Text(
                            'Séance du jour — vue d\'ensemble (lecture seule)',
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: () => _cloturerJournee(date),
                          child: const Text('Clôturer cette journée'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              // Choix du membre — visible uniquement s'il y a une journée de
              // cotisation ouverte. Ouvre l'écran Cotisation (voir
              // `cotisation_membre_screen.dart`) : cotisation, présence, et
              // toutes les autres actions au même endroit, avec possibilité
              // d'enchaîner sur le membre suivant.
              FutureBuilder<DateTime?>(
                future: _journeeOuverteFuture,
                builder: (context, journeeSnapshot) {
                  if (!journeeSnapshot.hasData ||
                      journeeSnapshot.data == null) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Aucune journée d\'épargne ouverte pour le moment — la '
                        'prochaine épargne ne sera possible qu\'à la date de la '
                        'prochaine échéance programmée.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '1. Épargne',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: null,
                          decoration: const InputDecoration(
                            labelText: 'Membre',
                            border: OutlineInputBorder(),
                          ),
                          items: membres
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m.id,
                                  child: Text(m.fullName),
                                ),
                              )
                              .toList(),
                          onChanged: (memberId) {
                            if (memberId != null) {
                              _ouvrirEcranCotisation(membres, memberId);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              // Encaissements déjà enregistrés aujourd'hui — reste visible en
              // permanence pendant la journée en cours, ne se vide jamais
              // après une confirmation (voir DECISIONS.md, "Encaissements de
              // la journée visibles en direct").
              FutureBuilder<DateTime?>(
                future: _journeeOuverteFuture,
                builder: (context, journeeSnapshot) {
                  final date = journeeSnapshot.data;
                  if (date == null) return const SizedBox.shrink();
                  return FutureBuilder<List<Echeance>>(
                    future: ref
                        .read(databaseProvider)
                        .echeancesResoluesPourDate(
                          cycleId: widget.cycleId,
                          date: date,
                        ),
                    builder: (context, echSnapshot) {
                      final lignes = echSnapshot.data ?? [];
                      if (lignes.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'Encaissements déjà enregistrés — '
                                '${date.day}/${date.month}/${date.year} (${lignes.length})',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            ...lignes.map(
                              (l) => _ligneEcheance(l, membresParId),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
