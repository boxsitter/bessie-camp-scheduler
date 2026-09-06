import '../ember_core.dart';

class HardcodedDomains {
  static final Organization ygs = Organization(
    id: 'ymca_of_greater_seattle-organization-rot-iezbojy',
    name: 'YMCA Of Greater Seattle',
    createdAt: DateTime.parse('2025-03-17T04:58:08.000Z').toUtc(),
  );

  static final Branch colman = Branch(
    id: 'colman-branch-org-ewuc68e',
    name: 'Colman',
    createdAt: DateTime.parse('2025-03-17T05:10:29.000Z').toUtc(),
  );

  static final Season season = Season(
    name: '2025',
    id: '2025-season-brn-RBpYT2E',
    createdAt: DateTime.parse('2025-03-17T05:19:16.000Z').toUtc(),
    start: DateTime(2025, 1, 1).toUtc(),
    end: DateTime(2026, 1, 1).toUtc(),
  );

  static final testSession = Session(
    name: 'Test Session',
    id: 'test_session-session-sea-y9D5nU5',
    start: DateTime.now(),
    createdAt: DateTime.parse('2025-03-17T05:35:01.000Z').toUtc(),
  );
}