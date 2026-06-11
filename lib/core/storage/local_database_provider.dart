import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_database_service.dart';

final localDatabaseProvider = FutureProvider<LocalDatabaseService>((ref) {
  return LocalDatabaseService.open();
});
