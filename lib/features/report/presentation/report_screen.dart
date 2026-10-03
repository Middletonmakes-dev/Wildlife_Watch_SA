import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/config/app_config.dart';
import '../../../app/providers.dart';
import '../../map/domain/map_provider.dart';
import '../data/photo_processor.dart';
import '../domain/incident.dart';
import '../domain/report_controller.dart';
import '../domain/report_draft.dart';
import 'thank_you_screen.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  late final ReportController controller;
  late final TextEditingController noteController;
  late final TextEditingController bearingController;
  late final String requestId;
  late final TileProvider tileProvider;

  @override
  void initState() {
    super.initState();
    requestId = 'report-${DateTime.now().microsecondsSinceEpoch}';
    tileProvider = ref.read(mapTileProviderFactoryProvider)();
    controller = ReportController(
      repository: ref.read(incidentRepositoryProvider),
      photoStorage: ref.read(photoStorageProvider),
      locationService: ref.read(locationServiceProvider),
      initialDraft: ReportDraft(requestId: requestId),
    );
    noteController = TextEditingController();
    bearingController = TextEditingController();
    controller.startLocation().then((_) {
      if (mounted) {
        _updateBearing();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    noteController.dispose();
    bearingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final config = ref.watch(appConfigProvider);
    final location = state.draft.location;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report a tortoise'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text('Location first',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            if (config.isDemo)
              const Text(
                  'Demo mode · synthetic reports only; nothing is sent to Firebase.'),
            const Text(
                'Allow GPS, tap the map or drag the pin. The map shown here is only for your report.'),
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: IgnorePointer(
                  ignoring: state.status == ReportStatus.submitting,
                  child: _ReportMap(
                    centre: config.mapCentre,
                    location: location,
                    zoom: config.initialMapZoom,
                    tileProvider: tileProvider,
                    onSelected: (point) {
                      controller.setManualLocation(
                        GeoCoordinate(
                          latitude: point.latitude,
                          longitude: point.longitude,
                          source: LocationSource.manualPin,
                        ),
                      );
                      _updateBearing();
                      setState(() {});
                    },
                  )),
            ),
            if (state.locationMessage != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(state.locationMessage!,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
            if (!config.isDemo)
              TextButton.icon(
                  onPressed: state.status == ReportStatus.submitting
                      ? null
                      : () async {
                          final locating = controller.startLocation();
                          setState(() {});
                          await locating;
                          if (mounted) {
                            _updateBearing();
                            setState(() {});
                          }
                        },
                  icon: const Icon(Icons.my_location),
                  label: const Text('Retry device GPS')),
            const SizedBox(height: 20),
            DropdownButtonFormField<IncidentType>(
              decoration: const InputDecoration(labelText: 'What happened?'),
              initialValue: state.draft.incidentType,
              items: IncidentType.values
                  .map((type) =>
                      DropdownMenuItem(value: type, child: Text(type.label)))
                  .toList(),
              onChanged: state.status == ReportStatus.submitting
                  ? null
                  : (value) {
                      if (value == null) return;
                      controller.updateDraft(
                        controller.state.draft.copyWith(incidentType: value),
                      );
                      setState(() {});
                    },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bearingController,
              enabled: state.status != ReportStatus.submitting,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Direction of travel (optional)',
                hintText: 'Compass bearing, 0 to 359 degrees',
              ),
              onChanged: (_) => _updateBearing(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              enabled: state.status != ReportStatus.submitting,
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
              decoration:
                  const InputDecoration(labelText: 'Short note (optional)'),
              onChanged: (value) => controller.updateDraft(
                controller.state.draft.copyWith(note: value),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: state.status == ReportStatus.submitting
                  ? null
                  : () => _pickPhoto(config),
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(state.draft.photoBytes == null
                  ? 'Add an optional photo'
                  : 'Photo selected'),
            ),
            const SizedBox(height: 20),
            if (state.message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(state.message!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            ElevatedButton(
              onPressed:
                  state.status == ReportStatus.submitting ? null : _submit,
              child: Text(state.status == ReportStatus.submitting
                  ? 'Saving…'
                  : 'Submit report'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateBearing() {
    final text = bearingController.text.trim();
    final value = text.isEmpty ? null : double.tryParse(text) ?? double.nan;
    final location = controller.state.draft.location;
    if (location == null) return;
    controller.updateDraft(
      controller.state.draft.copyWith(
        location: GeoCoordinate(
          latitude: location.latitude,
          longitude: location.longitude,
          accuracyMetres: location.accuracyMetres,
          source: location.source,
          directionBearing: value,
        ),
      ),
    );
  }

  Future<void> _pickPhoto(AppConfig config) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (bytes.length > 12 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'That photo is too large. Please choose a smaller image.')),
        );
      }
      return;
    }
    try {
      final processed =
          PhotoProcessor(maxLongestEdge: config.photoMaxLongestEdge)
              .process(Uint8List.fromList(bytes));
      if (processed.length > config.photoMaxBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('That photo is still too large after compression.')),
          );
        }
        return;
      }
      controller
          .updateDraft(controller.state.draft.copyWith(photoBytes: processed));
    } on FormatException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('That image could not be processed.')),
        );
      }
      return;
    }
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (controller.state.status == ReportStatus.submitting) return;
    final submission = controller.submit();
    if (mounted) setState(() {});
    await submission;
    if (!mounted) return;
    setState(() {});
    if (controller.state.status == ReportStatus.submitted) {
      context.go(
        '/thanks',
        extra: ThankYouData(
          message: controller.state.message,
          hasPhoto: controller.state.draft.photoBytes != null,
          photoUploaded: controller.state.photoUploaded,
          demo: ref.read(appConfigProvider).isDemo,
          incidentType: controller.state.draft.incidentType,
          retryPhoto: controller.state.draft.photoBytes != null &&
                  !controller.state.photoUploaded
              ? () async {
                  return controller.retryPhoto();
                }
              : null,
        ),
      );
    }
  }
}

class _ReportMap extends StatefulWidget {
  const _ReportMap(
      {required this.centre,
      required this.location,
      required this.zoom,
      required this.tileProvider,
      required this.onSelected});

  final LatLng centre;
  final GeoCoordinate? location;
  final ValueChanged<LatLng> onSelected;
  final double zoom;
  final TileProvider tileProvider;

  @override
  State<_ReportMap> createState() => _ReportMapState();
}

class _ReportMapState extends State<_ReportMap> {
  final _mapController = MapController();
  bool _dragging = false;
  math.Point<double>? _dragScreenPoint;

  @override
  void didUpdateWidget(covariant _ReportMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging &&
        oldWidget.location != widget.location &&
        widget.location != null) {
      _mapController.move(
          LatLng(widget.location!.latitude, widget.location!.longitude),
          _mapController.camera.zoom);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final point = widget.location == null
        ? widget.centre
        : LatLng(widget.location!.latitude, widget.location!.longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: point,
          initialZoom: widget.zoom,
          interactionOptions: InteractionOptions(
              flags: _dragging ? InteractiveFlag.none : InteractiveFlag.all),
          onTap: (_, tappedPoint) => widget.onSelected(tappedPoint),
        ),
        children: <Widget>[
          TileLayer(
            tileProvider: widget.tileProvider,
            urlTemplate: const OpenStreetMapProvider().tileUrl,
            userAgentPackageName: 'za.scarborough.tortoise_watch',
          ),
          MarkerLayer(
            markers: <Marker>[
              Marker(
                point: point,
                width: 48,
                height: 48,
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (_) {
                    _dragScreenPoint =
                        _mapController.camera.latLngToScreenPoint(point);
                    setState(() => _dragging = true);
                  },
                  onPointerMove: (details) {
                    final camera = _mapController.camera;
                    final previous = _dragScreenPoint;
                    if (previous == null) return;
                    _dragScreenPoint = math.Point(previous.x + details.delta.dx,
                        previous.y + details.delta.dy);
                    widget.onSelected(camera.pointToLatLng(_dragScreenPoint!));
                  },
                  onPointerUp: (_) {
                    _dragScreenPoint = null;
                    setState(() => _dragging = false);
                  },
                  onPointerCancel: (_) {
                    _dragScreenPoint = null;
                    setState(() => _dragging = false);
                  },
                  child: const Icon(Icons.location_pin,
                      semanticLabel: 'Drag report location pin',
                      color: Colors.red,
                      size: 42),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: Colors.white.withValues(alpha: 0.9),
              child: Text(
                  'Tap or drag the pin · ${const OpenStreetMapProvider().attribution}'),
            ),
          ),
        ],
      ),
    );
  }
}
