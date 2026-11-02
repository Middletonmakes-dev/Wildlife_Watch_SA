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
import '../../../app/theme/app_theme.dart';
import '../../map/domain/map_provider.dart';
import '../data/photo_processor.dart';
import '../domain/incident.dart';
import '../domain/report_controller.dart';
import '../domain/report_draft.dart';
import 'direction_wheel.dart';
import 'thank_you_screen.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});
  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  late final ReportController controller;
  late final TextEditingController noteController;
  late final TileProvider tileProvider;
  int _step = 0;
  bool _editingLocation = true;
  bool _directionSkipped = false;
  bool _showNote = false;
  int _locationChoiceGeneration = 0;
  int _gpsFixGeneration = 0;

  @override
  void initState() {
    super.initState();
    tileProvider = ref.read(mapTileProviderFactoryProvider)();
    controller = ReportController(
      repository: ref.read(incidentRepositoryProvider),
      photoStorage: ref.read(photoStorageProvider),
      locationService: ref.read(locationServiceProvider),
      initialDraft: ReportDraft(
          requestId: 'report-${DateTime.now().microsecondsSinceEpoch}'),
    );
    noteController = TextEditingController();
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  void _setBearing(double? bearing) {
    final location = controller.state.draft.location;
    if (location == null) return;
    controller.updateDraft(controller.state.draft.copyWith(
        location: GeoCoordinate(
      latitude: location.latitude,
      longitude: location.longitude,
      accuracyMetres: location.accuracyMetres,
      source: location.source,
      directionBearing: bearing,
    )));
  }

  void _selectType(IncidentType type) {
    controller.updateDraft(controller.state.draft.copyWith(incidentType: type));
    if (type == IncidentType.deadRoadkill) {
      _setBearing(null);
      _directionSkipped = false;
    }
    setState(() => _step = 1);
  }

  Future<void> _locate() async {
    final generation = ++_locationChoiceGeneration;
    final locating = controller.startLocation();
    setState(() {});
    final accepted = await locating;
    if (!mounted) return;
    setState(() {
      if (accepted && generation == _locationChoiceGeneration) {
        _editingLocation = false;
        _directionSkipped = false;
        _gpsFixGeneration++;
      }
    });
  }

  void _editLocation() {
    _locationChoiceGeneration++;
    controller.cancelLocationRequest();
    setState(() => _editingLocation = true);
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final config = ref.watch(appConfigProvider);
    final location = state.draft.location;
    final busy = state.status == ReportStatus.submitting;
    final roadkill = state.draft.incidentType == IncidentType.deadRoadkill;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report a tortoise'),
        leading: BackButton(
            onPressed: busy
                ? null
                : () {
                    if (_step == 1) {
                      setState(() => _step = 0);
                    } else {
                      context.go('/');
                    }
                  }),
      ),
      bottomNavigationBar: _step == 0
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppTheme.rule))),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (state.message != null)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(state.message!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error))),
                  ElevatedButton(
                      onPressed: busy ? null : _submit,
                      child: Text(busy ? 'Saving…' : 'Submit report')),
                  const SizedBox(height: 5),
                  Text(
                      config.isDemo
                          ? 'Demo mode · saved locally, nothing sent to Firebase'
                          : 'Exact location stays private.',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center),
                ]),
              )),
      body: SafeArea(
          child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: IgnorePointer(
                    ignoring: busy,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      children: [
                        const Divider(),
                        Padding(
                            padding: const EdgeInsets.only(top: 14, bottom: 8),
                            child: Text('SCARBOROUGH · ${_step + 1} OF 2',
                                style: const TextStyle(
                                    fontSize: 11, letterSpacing: 1.1))),
                        if (_step == 0) ...[
                          Text('What did you see?',
                              style:
                                  Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 10),
                          const Text('Choose the closest match.'),
                          const SizedBox(height: 24),
                          for (final option in [
                            (
                              type: IncidentType.aliveCrossingRoad,
                              label: 'Crossing road',
                              detail: 'Alive, moving across the road',
                              icon: Icons.alt_route
                            ),
                            (
                              type: IncidentType.aliveNearRoad,
                              label: 'Near the road',
                              detail: 'Alive, beside the road',
                              icon: Icons.eco_outlined
                            ),
                            (
                              type: IncidentType.injured,
                              label: 'Injured',
                              detail: 'A tortoise that appears hurt',
                              icon: Icons.healing_outlined
                            ),
                            (
                              type: IncidentType.deadRoadkill,
                              label: 'Roadkill',
                              detail: 'A tortoise killed on the road',
                              icon: Icons.warning_amber_outlined
                            ),
                          ]) ...[
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 9),
                              minVerticalPadding: 12,
                              leading: Icon(option.icon,
                                  color: AppTheme.rust, size: 28),
                              title: Text(option.label,
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              subtitle: Text(option.detail),
                              trailing: Icon(
                                  state.draft.incidentType == option.type
                                      ? Icons.check
                                      : Icons.arrow_forward,
                                  color: AppTheme.rust,
                                  size: 22),
                              onTap: () => _selectType(option.type),
                            ),
                            const Divider(),
                          ],
                          const SizedBox(height: 20),
                          const Text(
                              'Keep yourself safe. You can report once you are clear of the road.'),
                          if (config.isDemo)
                            Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: Text(
                                    'Demo mode · reports stay in this browser.',
                                    style:
                                        Theme.of(context).textTheme.bodySmall)),
                        ] else ...[
                          Text('Where was it?',
                              style:
                                  Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(
                                child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8)),
                                    onPressed:
                                        state.status == ReportStatus.locating
                                            ? null
                                            : _locate,
                                    icon:
                                        const Icon(Icons.my_location, size: 18),
                                    label: Text(
                                        state.status == ReportStatus.locating
                                            ? 'Finding location…'
                                            : 'Use my location',
                                        style: const TextStyle(fontSize: 13)))),
                            const SizedBox(width: 8),
                            Expanded(
                                child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8)),
                                    onPressed: _editLocation,
                                    icon: const Icon(Icons.place_outlined,
                                        size: 18),
                                    label: const Text('Place a pin',
                                        style: TextStyle(fontSize: 13)))),
                          ]),
                          if (state.status == ReportStatus.locating ||
                              state.locationMessage != null)
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Semantics(
                                    liveRegion: true,
                                    child: Text(
                                        state.status == ReportStatus.locating
                                            ? 'Waiting for your browser… You can place a pin instead.'
                                            : state.locationMessage!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall))),
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                  _editingLocation
                                      ? 'Tap the map or drag the pin to the sighting.'
                                      : roadkill
                                          ? 'Location selected. Move the pin if needed.'
                                          : 'Which way was it going? Drag or tap the arrow.',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium)),
                          SizedBox(
                              key: const Key('report-map-frame'),
                              height: 270,
                              child: _ReportMap(
                                centre: config.mapCentre,
                                location: location,
                                zoom: config.reportMapZoom,
                                gpsFixGeneration: _gpsFixGeneration,
                                tileProvider: tileProvider,
                                editing: _editingLocation,
                                showDirection: !roadkill,
                                onLocationConfirmed: () =>
                                    setState(() => _editingLocation = false),
                                onBearing: (value) => setState(() {
                                  _setBearing(value);
                                  _directionSkipped = false;
                                }),
                                onSelected: (point) {
                                  _locationChoiceGeneration++;
                                  final priorBearing =
                                      location?.directionBearing;
                                  controller.setManualLocation(GeoCoordinate(
                                      latitude: point.latitude,
                                      longitude: point.longitude,
                                      source: LocationSource.manualPin,
                                      directionBearing: priorBearing));
                                  setState(() {});
                                },
                              )),
                          if (location != null)
                            Row(children: [
                              Expanded(
                                  child: Text(
                                      roadkill
                                          ? 'Location selected'
                                          : _directionSkipped
                                              ? 'Direction skipped'
                                              : location.directionBearing ==
                                                      null
                                                  ? 'Direction optional'
                                                  : 'Direction selected',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall)),
                              Expanded(
                                  child: TextButton(
                                      onPressed: _editLocation,
                                      child: const Text('Move pin',
                                          textAlign: TextAlign.center))),
                              if (!roadkill)
                                Expanded(
                                    child: TextButton(
                                        onPressed: () => setState(() {
                                              _setBearing(null);
                                              _directionSkipped = true;
                                              _editingLocation = false;
                                            }),
                                        child: const Text('Skip direction',
                                            textAlign: TextAlign.center))),
                            ]),
                          const Divider(),
                          Row(children: [
                            Expanded(
                                child: TextButton.icon(
                                    onPressed: () => _choosePhotoSource(config),
                                    icon: const Icon(
                                        Icons.photo_camera_outlined,
                                        size: 20),
                                    label: Text(state.draft.photoBytes == null
                                        ? 'Add an optional photo'
                                        : 'Photo selected'))),
                            TextButton.icon(
                                onPressed: () =>
                                    setState(() => _showNote = !_showNote),
                                icon: const Icon(Icons.notes, size: 20),
                                label: const Text('Add note')),
                          ]),
                          if (_showNote)
                            TextField(
                                controller: noteController,
                                minLines: 2,
                                maxLines: 4,
                                maxLength: 500,
                                decoration: const InputDecoration(
                                    labelText: 'Short note (optional)'),
                                onChanged: (value) => setState(() => controller
                                    .updateDraft(controller.state.draft
                                        .copyWith(note: value)))),
                        ],
                      ],
                    )),
              ))),
    );
  }

  Future<void> _choosePhotoSource(AppConfig config) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose existing photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (!mounted || source == null) return;
    await _pickPhoto(config, source);
  }

  Future<void> _pickPhoto(AppConfig config, ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
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
      required this.gpsFixGeneration,
      required this.tileProvider,
      required this.onSelected,
      required this.editing,
      required this.showDirection,
      required this.onBearing,
      required this.onLocationConfirmed});
  final LatLng centre;
  final GeoCoordinate? location;
  final ValueChanged<LatLng> onSelected;
  final ValueChanged<double> onBearing;
  final VoidCallback onLocationConfirmed;
  final double zoom;
  final int gpsFixGeneration;
  final TileProvider tileProvider;
  final bool editing;
  final bool showDirection;
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
    final next = widget.location;
    final previous = oldWidget.location;
    final gpsFix = oldWidget.gpsFixGeneration != widget.gpsFixGeneration;
    if (!_dragging &&
        next != null &&
        (gpsFix ||
            previous?.latitude != next.latitude ||
            previous?.longitude != next.longitude)) {
      _mapController.move(LatLng(next.latitude, next.longitude),
          gpsFix ? widget.zoom : _mapController.camera.zoom);
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
    final directionMode =
        !widget.editing && widget.location != null && widget.showDirection;
    return ClipRect(
        child: FlutterMap(
      mapController: _mapController,
      options: MapOptions(
          initialCenter: point,
          initialZoom: widget.zoom,
          interactionOptions: InteractionOptions(
              flags: _dragging || !widget.editing
                  ? InteractiveFlag.none
                  : InteractiveFlag.all & ~InteractiveFlag.rotate),
          onTap: (_, tappedPoint) {
            if (widget.editing) {
              widget.onSelected(tappedPoint);
              widget.onLocationConfirmed();
            }
          }),
      children: [
        TileLayer(
            tileProvider: widget.tileProvider,
            urlTemplate: const OpenStreetMapProvider().tileUrl,
            userAgentPackageName: 'za.scarborough.tortoise_watch'),
        MarkerLayer(markers: [
          Marker(
              point: point,
              width: directionMode ? 168 : 48,
              height: directionMode ? 168 : 48,
              child: directionMode
                  ? DirectionWheel(
                      bearing: widget.location!.directionBearing,
                      onChanged: widget.onBearing)
                  : Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: widget.editing
                          ? (_) {
                              _dragScreenPoint = _mapController.camera
                                  .latLngToScreenPoint(point);
                              setState(() => _dragging = true);
                              widget.onSelected(point);
                            }
                          : null,
                      onPointerMove: widget.editing
                          ? (details) {
                              final previous = _dragScreenPoint;
                              if (previous == null) return;
                              _dragScreenPoint = math.Point(
                                  previous.x + details.delta.dx,
                                  previous.y + details.delta.dy);
                              widget.onSelected(_mapController.camera
                                  .pointToLatLng(_dragScreenPoint!));
                            }
                          : null,
                      onPointerUp: (_) => _finishDrag(),
                      onPointerCancel: (_) => _finishDrag(),
                      child: const Icon(Icons.location_pin,
                          semanticLabel: 'Drag report location pin',
                          color: AppTheme.rust,
                          size: 42),
                    )),
        ]),
        const Positioned(
            top: 10,
            right: 10,
            child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.white),
                child: Padding(
                    padding: EdgeInsets.all(7),
                    child: Column(children: [
                      Icon(Icons.north, size: 17),
                      Text('N', style: TextStyle(fontSize: 11))
                    ])))),
        Align(
            alignment: Alignment.bottomCenter,
            child: Container(
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                color: Colors.white.withValues(alpha: .92),
                child: const Text('© OpenStreetMap contributors',
                    style: TextStyle(fontSize: 10)))),
      ],
    ));
  }

  void _finishDrag() {
    _dragScreenPoint = null;
    if (mounted && _dragging) {
      setState(() => _dragging = false);
      widget.onLocationConfirmed();
    }
  }
}
