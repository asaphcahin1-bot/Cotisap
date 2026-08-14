import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/data/local/database.dart';

/// Un membre = un seul carnet, toujours (voir DECISIONS.md, "Un membre
/// = un seul carnet") : le même nom complet ou le même numéro de
/// téléphone ne peut pas servir à créer un second membre/carnet **dans
/// le même groupe**. Cette unicité est strictement scoped au groupe —
/// une personne peut appartenir à autant de groupes qu'elle veut avec
/// la même identité (voir [AppDatabase.nomOuTelephoneDejaUtiliseDansLeGroupe]).
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> creerGroupe([String name = 'Groupe test']) async {
    return db.creerGroupe(
      name: name,
      cycleDurationMonths: 9,
      meetingFrequency: 'mensuelle',
    );
  }

  test('refuse un second membre avec le même numéro de téléphone dans le même groupe',
      () async {
    final groupId = await creerGroupe();
    await db.ajouterMembre(
      groupId: groupId,
      fullName: 'Aya Kone',
      phoneNumber: '+2250000001',
    );

    expect(
      () => db.ajouterMembre(
        groupId: groupId,
        fullName: 'Un autre nom',
        phoneNumber: '+2250000001',
      ),
      throwsStateError,
    );
  });

  test('refuse un second membre avec le même nom complet (insensible à la casse/espaces)',
      () async {
    final groupId = await creerGroupe();
    await db.ajouterMembre(
      groupId: groupId,
      fullName: 'Aya Kone',
      phoneNumber: '+2250000001',
    );

    expect(
      () => db.ajouterMembre(
        groupId: groupId,
        fullName: '  aya KONE  ',
        phoneNumber: '+2250000002',
      ),
      throwsStateError,
    );
  });

  test('accepte un nom différent et un téléphone différent', () async {
    final groupId = await creerGroupe();
    await db.ajouterMembre(
      groupId: groupId,
      fullName: 'Aya Kone',
      phoneNumber: '+2250000001',
    );

    final id = await db.ajouterMembre(
      groupId: groupId,
      fullName: 'Seydou Traore',
      phoneNumber: '+2250000002',
    );
    expect(id, isNotEmpty);
  });

  test('la même identité (nom + téléphone) est autorisée dans un AUTRE groupe',
      () async {
    final groupA = await creerGroupe('Groupe A');
    final groupB = await creerGroupe('Groupe B');
    await db.ajouterMembre(
      groupId: groupA,
      fullName: 'Aya Kone',
      phoneNumber: '+2250000001',
    );

    // Même nom, même téléphone, mais un groupe différent : autorisé.
    final id = await db.ajouterMembre(
      groupId: groupB,
      fullName: 'Aya Kone',
      phoneNumber: '+2250000001',
    );
    expect(id, isNotEmpty);
  });

  test('deux membres sans téléphone peuvent coexister (unicité du nom seul)',
      () async {
    final groupId = await creerGroupe();
    await db.ajouterMembre(
      groupId: groupId,
      fullName: 'Membre sans tel A',
      phoneNumber: null,
    );

    final id = await db.ajouterMembre(
      groupId: groupId,
      fullName: 'Membre sans tel B',
      phoneNumber: null,
    );
    expect(id, isNotEmpty);
  });
}
