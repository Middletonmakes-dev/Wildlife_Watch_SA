import '../data/incident_repository.dart';
import 'dart:typed_data';
import '../data/photo_storage.dart';
import 'incident.dart';
import 'location_service.dart';
import 'report_draft.dart';

enum ReportStatus { idle, locating, ready, submitting, submitted, error }

class ReportState {
  const ReportState({
    required this.draft,
    this.status = ReportStatus.idle,
    this.message,
    this.locationMessage,
    this.incidentId,
    this.photoUploaded = false,
  });

  final ReportDraft draft;
  final ReportStatus status;
  final String? message;
  final String? locationMessage;
  final String? incidentId;
  final bool photoUploaded;

  ReportState copyWith({
    ReportDraft? draft,
    ReportStatus? status,
    String? message,
    bool clearMessage = false,
    String? locationMessage,
    String? incidentId,
    bool? photoUploaded,
  }) {
    return ReportState(
      draft: draft ?? this.draft,
      status: status ?? this.status,
      message: clearMessage ? null : message ?? this.message,
      locationMessage: locationMessage ?? this.locationMessage,
      incidentId: incidentId ?? this.incidentId,
      photoUploaded: photoUploaded ?? this.photoUploaded,
    );
  }
}

class ReportController {
  ReportController({
    required IncidentRepository repository,
    required PhotoStorage photoStorage,
    required LocationService locationService,
    required ReportDraft initialDraft,
  })  : _repository = repository,
        _photoStorage = photoStorage,
        _locationService = locationService,
        _state = ReportState(draft: initialDraft);

  final IncidentRepository _repository;
  final PhotoStorage _photoStorage;
  final LocationService _locationService;
  ReportState _state;
  bool _manualLocationSelected = false;
  bool _inFlight = false;
  int _locationGeneration = 0;
  Uint8List? _committedPhoto;

  ReportState get state => _state;

  Future<bool> startLocation() async {
    if (_inFlight || _state.incidentId != null) return false;
    final generation = ++_locationGeneration;
    _manualLocationSelected = false;
    _state = _state.copyWith(status: ReportStatus.locating, clearMessage: true);
    try {
      final result = await _locationService.currentLocation();
      if (generation != _locationGeneration || _inFlight) return false;
      return await applyLocationResult(result);
    } on LocationException catch (error) {
      if (generation != _locationGeneration || _inFlight) return false;
      _state = _state.copyWith(
        status: ReportStatus.ready,
        locationMessage: error.message,
      );
    } catch (_) {
      if (generation != _locationGeneration || _inFlight) return false;
      _state = _state.copyWith(
        status: ReportStatus.ready,
        locationMessage:
            'Location is unavailable. Tap the map to choose it manually.',
      );
    }
    return false;
  }

  Future<bool> applyLocationResult(LocationResult result) async {
    if (_manualLocationSelected || _inFlight || _state.incidentId != null)
      return false;
    _state = _state.copyWith(
      draft: _state.draft.copyWith(location: result.coordinate),
      status: ReportStatus.ready,
      locationMessage: result.isLowAccuracy
          ? 'GPS accuracy is low. Tap the map to adjust the pin.'
          : 'Location ready. You can move the pin if needed.',
    );
    return true;
  }

  void setManualLocation(GeoCoordinate coordinate) {
    if (_inFlight || _state.incidentId != null) return;
    _locationGeneration++;
    _manualLocationSelected = true;
    _state = _state.copyWith(
      draft: _state.draft.copyWith(location: coordinate),
      status: ReportStatus.ready,
      locationMessage: 'Manual location selected.',
      clearMessage: true,
    );
  }

  /// Selecting manual editing cancels acceptance of any pending GPS result,
  /// without silently confirming the map centre as a report location.
  void cancelLocationRequest() {
    if (_inFlight || _state.incidentId != null) return;
    _locationGeneration++;
    _manualLocationSelected = true;
    if (_state.status == ReportStatus.locating) {
      _state = _state.copyWith(status: ReportStatus.ready);
    }
  }

  void updateDraft(ReportDraft draft) {
    if (_inFlight || _state.incidentId != null) return;
    _state = _state.copyWith(draft: draft, clearMessage: true);
  }

  Future<void> submit() async {
    if (_inFlight || _state.incidentId != null) return;
    final validationErrors = _state.draft.validate();
    if (validationErrors.isNotEmpty) {
      _state = _state.copyWith(
        status: ReportStatus.error,
        message: validationErrors.first,
      );
      return;
    }

    final submissionDraft = _state.draft;
    _inFlight = true;
    _locationGeneration++;
    _state =
        _state.copyWith(status: ReportStatus.submitting, clearMessage: true);
    late final SubmissionResult result;
    try {
      result = await _repository.submit(submissionDraft);
    } on ReportRepositoryException catch (error) {
      _state =
          _state.copyWith(status: ReportStatus.error, message: error.message);
      _inFlight = false;
      return;
    } catch (_) {
      _state = _state.copyWith(
        status: ReportStatus.error,
        message: 'The report could not be saved. Please try again.',
      );
      _inFlight = false;
      return;
    }

    var photoUploaded = _state.photoUploaded;
    var message = 'Thank you for helping protect local tortoises.';
    final bytes = submissionDraft.photoBytes;
    _committedPhoto = bytes;
    if (bytes != null && !photoUploaded) {
      try {
        await _photoStorage.upload(incidentId: result.incidentId, bytes: bytes);
        photoUploaded = true;
      } on PhotoStorageException {
        message = 'Report saved. The optional photo could not be uploaded.';
      } catch (_) {
        message = 'Report saved. The optional photo could not be uploaded.';
      }
    }
    _state = _state.copyWith(
      status: ReportStatus.submitted,
      incidentId: result.incidentId,
      photoUploaded: photoUploaded,
      message: message,
    );
    _inFlight = false;
  }

  Future<bool> retryPhoto() async {
    final incidentId = _state.incidentId;
    final bytes = _committedPhoto;
    if (_inFlight || incidentId == null || bytes == null)
      return _state.photoUploaded;
    if (_state.photoUploaded) return true;
    _inFlight = true;
    try {
      await _photoStorage.upload(incidentId: incidentId, bytes: bytes);
      _state = _state.copyWith(photoUploaded: true);
      return true;
    } catch (_) {
      return false;
    } finally {
      _inFlight = false;
    }
  }
}
