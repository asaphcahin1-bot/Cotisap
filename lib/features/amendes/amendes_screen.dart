import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting.dart';
import '../../data/local/database.dart';
import '../../state/providers.dart';
import '../cotisations/amende_fonds_dialogs.dart';
import '../cotisations/amende_resolution_dialogs.dart';

/// Écran "Amendes" dédié — toutes les amendes du cycle en un seul
/// endroit, plutôt que dispersées entre l'écran Cotisations et l'écran
/// Répartition (voir DECISIONS.md, "Section Amendes dédiée" ;
/// RETOURS_TERRAIN.md, point 5). Purement une vue + des actions déjà
/// existantes ailleurs (payer, corriger, ajouter) — aucune nouvelle
/// règle métier.
class AmendesScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String cycleId;

  const AmendesScreen({
    super.key,
    required this.groupId,
    required this.cycleId,
  });

  @override
  ConsumerState<AmendesScreen> createState() => _AmendesScreenState();
}

enum _Filtre { toutes, enAttente, reglees, annulees }

class _AmendesScreenState extends ConsumerState<AmendesScreen> {
  late Future<_AmendesData> _dataFuture;
  _Filtre _filtre = _Filtre.enAttente;

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

  Future<_AmendesData> _fetch(AppDatabase db) async {
    final amendes = await db.amendesDuCycle(widget.cycleId);
    final membres = await db.membresDuGroupe(widget.groupId);
    final membresParId = {for (final m in membres) m.id: m};
    final statuts = await db.statutsAmendes(widget.cycleId);
    final soldes = <String, int>{};
    for (final a in amendes) {
      soldes[a.id] = await db.soldeRestantAmendeFcfa(a.id);
    }
    final motifsCatalogue = await db.motifsAmendeActifsDuGroupe(
      widget.groupId,
    );
    return _AmendesData(
      amendes: amendes,
      membresParId: membresParId,
      membres: membres,
      statuts: statuts,
      soldes: soldes,
      motifsCatalogue: motifsCatalogue,
    );
  }

  Future<void> _payer(Amende amende, int solde) async {
    final db = ref.read(databaseProvider);
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
    await showPayerAmendeDialog(
      context: context,
      db: db,
      amende: amende,
      solde: solde,
      agentPhone: agentPhone,
      onSaved: _reload,
    );
  }

  Future<void> _corriger(Amende amende, Member membre) async {
    final db = ref.read(databaseProvider);
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
    await showCorrigerAmendeErreurDialog(
      context: context,
      db: db,
      groupId: widget.groupId,
      cycleId: widget.cycleId,
      memberId: membre.id,
      membreNom: membre.fullName,
      amende: amende,
      agentPhone: agentPhone,
      onSaved: _reload,
    );
  }

  Future<void> _openAddAmendeDialog(_AmendesData data) async {
    final db = ref.read(databaseProvider);
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
    await showAddAmendeDialog(
      context: context,
      db: db,
      groupId: widget.groupId,
      cycleId: widget.cycleId,
      agentPhone: agentPhone,
      membres: data.membres,
      motifsCatalogue: data.motifsCatalogue,
      onSaved: _reload,
    );
  }

  bool _correspondAuFiltre(String statut) {
    switch (_filtre) {
      case _Filtre.toutes:
        return true;
      case _Filtre.enAttente:
        return statut == 'en_attente';
      case _Filtre.reglees:
        return statut == 'reglee';
      case _Filtre.annulees:
        return statut == 'annulee';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Amendes')),
      body: FutureBuilder<_AmendesData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final visibles = data.amendes
              .where((a) => _correspondAuFiltre(data.statuts[a.id] ?? 'en_attente'))
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('En attente'),
                      selected: _filtre == _Filtre.enAttente,
                      onSelected: (_) =>
                          setState(() => _filtre = _Filtre.enAttente),
                    ),
                    ChoiceChip(
                      label: const Text('Réglées'),
                      selected: _filtre == _Filtre.reglees,
                      onSelected: (_) =>
                          setState(() => _filtre = _Filtre.reglees),
                    ),
                    ChoiceChip(
                      label: const Text('Annulées'),
                      selected: _filtre == _Filtre.annulees,
                      onSelected: (_) =>
                          setState(() => _filtre = _Filtre.annulees),
                    ),
                    ChoiceChip(
                      label: const Text('Toutes'),
                      selected: _filtre == _Filtre.toutes,
                      onSelected: (_) =>
                          setState(() => _filtre = _Filtre.toutes),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: visibles.isEmpty
                    ? const Center(child: Text('Aucune amende ici.'))
                    : ListView.separated(
                        itemCount: visibles.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final a = visibles[index];
                          final membre = data.membresParId[a.memberId];
                          final statut = data.statuts[a.id] ?? 'en_attente';
                          final solde = data.soldes[a.id] ?? a.montantFcfa;
                          return ListTile(
                            title: Text(
                              '${membre?.fullName ?? a.memberId} — ${a.motif}'
                              ' (carnet ${a.carnetNumero})',
                            ),
                            subtitle: Text(
                              _sousTitre(a, statut, solde),
                            ),
                            leading: Icon(
                              statut == 'reglee'
                                  ? Icons.check_circle
                                  : statut == 'annulee'
                                  ? Icons.cancel_outlined
                                  : Icons.hourglass_top,
                              color: statut == 'reglee'
                                  ? Colors.green
                                  : statut == 'annulee'
                                  ? Theme.of(context).colorScheme.outline
                                  : Colors.orange,
                            ),
                            trailing: statut == 'en_attente'
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (a.estAutoGeneree)
                                        TextButton(
                                          onPressed: membre == null
                                              ? null
                                              : () => _corriger(a, membre),
                                          child: const Text('Erreur'),
                                        ),
                                      TextButton(
                                        onPressed: () => _payer(a, solde),
                                        child: const Text('Payer'),
                                      ),
                                    ],
                                  )
                                : null,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FutureBuilder<_AmendesData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => _openAddAmendeDialog(snapshot.data!),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une amende'),
          );
        },
      ),
    );
  }

  String _sousTitre(Amende a, String statut, int solde) {
    final libelleStatut = switch (statut) {
      'reglee' => 'Réglée',
      'annulee' => 'Annulée',
      _ => 'En attente',
    };
    if (statut == 'en_attente' && solde != a.montantFcfa) {
      return '$libelleStatut — solde restant : ${formatFcfa(solde)} '
          '(sur ${formatFcfa(a.montantFcfa)})';
    }
    return '$libelleStatut — ${formatFcfa(a.montantFcfa)}';
  }
}

class _AmendesData {
  final List<Amende> amendes;
  final Map<String, Member> membresParId;
  final List<Member> membres;
  final Map<String, String> statuts;
  final Map<String, int> soldes;
  final List<MotifsAmendeData> motifsCatalogue;

  const _AmendesData({
    required this.amendes,
    required this.membresParId,
    required this.membres,
    required this.statuts,
    required this.soldes,
    required this.motifsCatalogue,
  });
}
