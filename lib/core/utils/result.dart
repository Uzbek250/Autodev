import '../error/failures.dart';

/// A minimal Either-style result type so the domain/data layers can return
/// either a [Failure] or a value of type [T] without pulling in an external
/// functional-programming package (keeps pubspec to the exact spec'd deps).
class Result<T> {
  final Failure? failure;
  final T? value;

  const Result._({this.failure, this.value});

  factory Result.success(T value) => Result._(value: value);
  factory Result.error(Failure failure) => Result._(failure: failure);

  bool get isSuccess => failure == null;
  bool get isError => failure != null;

  /// Runs [onSuccess] if this is a success, otherwise [onError].
  R fold<R>(R Function(Failure f) onError, R Function(T v) onSuccess) {
    if (isError) return onError(failure as Failure);
    return onSuccess(value as T);
  }
}
