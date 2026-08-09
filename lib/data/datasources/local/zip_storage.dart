/// Platform-aware ZIP storage and sharing.
/// Native builds use the filesystem; Web uses browser download/share APIs.
export 'zip_storage_io.dart'
    if (dart.library.html) 'zip_storage_web.dart';
