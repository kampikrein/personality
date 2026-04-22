// TDD Red — Cycle 3 (intent_placement_setting pipeline)
// Spec:  docs/2_tarot_draw/03_draw_experience_settings/050_TDD_Red_cycle3_flow_integration.md
// Scope: docs/2_tarot_draw/03_draw_experience_settings/041_Scope_intent_placement_setting.md
//
// Purpose
// -------
// Failing unit tests for ReadingRepository.updateQuestion:
//   T1 — updateQuestion persists updated text
//   T2 — updateQuestion(null) clears question
//
// Red expectation
// ---------------
// ReadingRepository.updateQuestion does not exist yet → compile failure → RED.
//
// Green target (cycle 3 impl)
// ---------------------------
// Add `Future<void> updateQuestion(String readingId, String? question)` to
// ReadingRepository + ReadingRepositoryImpl (mirror of updateNotes).

import 'package:flutter_test/flutter_test.dart';
import 'package:personality_mobile/features/reading/domain/repositories/reading_repository.dart';

// ---------------------------------------------------------------------------
// Fake implementation — in-memory only, mirrors updateNotes pattern
// ---------------------------------------------------------------------------

class _FakeReadingRepo implements ReadingRepository {
  final Map<String, String?> _questions = {};

  @override
  Future<void> updateQuestion(String readingId, String? question) async {
    _questions[readingId] = question;
  }

  // The test only exercises updateQuestion, so all other methods can throw.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not implemented');
}

void main() {
  group('ReadingRepository.updateQuestion', () {
    // -----------------------------------------------------------------------
    // T1 — updateQuestion persists updated text
    // -----------------------------------------------------------------------
    test(
      'T1 updateQuestion persists updated text',
      () async {
        final repo = _FakeReadingRepo();
        repo._questions['reading-1'] = 'initial';

        await repo.updateQuestion('reading-1', 'updated');

        expect(
          repo._questions['reading-1'],
          equals('updated'),
          reason: 'updateQuestion must overwrite the stored question with the new value',
        );
      },
    );

    // -----------------------------------------------------------------------
    // T2 — updateQuestion(null) clears question
    // -----------------------------------------------------------------------
    test(
      'T2 updateQuestion with null clears the question',
      () async {
        final repo = _FakeReadingRepo();
        repo._questions['reading-2'] = 'initial';

        await repo.updateQuestion('reading-2', null);

        expect(
          repo._questions['reading-2'],
          isNull,
          reason: 'updateQuestion(null) must store null, clearing the question field',
        );
      },
    );
  });
}
