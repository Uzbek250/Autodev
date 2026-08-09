/// Platform-aware database helper.
/// Web builds use browser storage; Android/iOS/desktop builds keep SQLite.
export 'database_helper_io.dart'
    if (dart.library.html) 'database_helper_web.dart';
