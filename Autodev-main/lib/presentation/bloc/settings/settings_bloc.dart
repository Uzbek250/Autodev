import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/file_entity.dart';
import '../../../domain/repositories/settings_repository.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

class SettingsLoadEvent extends SettingsEvent {
  const SettingsLoadEvent();
}

class SettingsSaveEvent extends SettingsEvent {
  final AppSettingsEntity settings;
  const SettingsSaveEvent(this.settings);
  @override
  List<Object?> get props => [settings];
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class SettingsState extends Equatable {
  const SettingsState();
  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsState {
  final AppSettingsEntity settings;
  const SettingsLoaded(this.settings);
  @override
  List<Object?> get props => [settings];
}

class SettingsSaved extends SettingsState {
  final AppSettingsEntity settings;
  const SettingsSaved(this.settings);
  @override
  List<Object?> get props => [settings];
}

class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository repository;

  SettingsBloc(this.repository) : super(const SettingsInitial()) {
    on<SettingsLoadEvent>(_onLoad);
    on<SettingsSaveEvent>(_onSave);
  }

  Future<void> _onLoad(
      SettingsLoadEvent event, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading());
    try {
      final settings = await repository.getSettings();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError('Sozlamalar yuklanmadi: ${e.toString()}'));
    }
  }

  Future<void> _onSave(
      SettingsSaveEvent event, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading());
    try {
      await repository.saveSettings(event.settings);
      emit(SettingsSaved(event.settings));
    } catch (e) {
      emit(SettingsError('Sozlamalar saqlanmadi: ${e.toString()}'));
    }
  }
}
