import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:maps/widgets/reminder_marker_widget.dart';

class MapPage extends StatefulWidget {
  final bool selectionMode;
  const MapPage({super.key, this.selectionMode = false});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late final MapController _mapController;
  final List<Marker> _markers = [];
  LatLng? _selectedPoint;

  double _envDouble(String key, double fallback) {
    final v = dotenv.env[key];
    if (v == null) return fallback;
    return double.tryParse(v) ?? fallback;
  }

  String _envStr(String key, String fallback) {
    return dotenv.env[key] ?? fallback;
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    final center = LatLng(
      _envDouble('MAP_INITIAL_LAT', 0.0),
      _envDouble('MAP_INITIAL_LNG', 0.0),
    );

    _markers.addAll([
      _buildMarker(center, 'Inicio'),
      _buildMarker(LatLng(center.latitude + 0.01, center.longitude + 0.01), 'Punto A'),
      _buildMarker(LatLng(center.latitude - 0.01, center.longitude - 0.01), 'Punto B'),
    ]);
  }

  Marker _buildMarker(LatLng point, String title) {
    return Marker(
      point: point,
      width: 120,
      height: 60,
      alignment: Alignment.topCenter,
      child: ReminderMarkerWidget(title: title),
    );
  }

  Marker _buildSelectionMarker(LatLng point) {
    return Marker(
      point: point,
      width: 40,
      height: 40,
      alignment: Alignment.center,
      child: const Icon(Icons.location_on, color: Colors.red, size: 38),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = LatLng(
      _envDouble('MAP_INITIAL_LAT', 0.0),
      _envDouble('MAP_INITIAL_LNG', 0.0),
    );
    final initialZoom = _envDouble('MAP_INITIAL_ZOOM', 13.0);

    final tileUrl = _envStr('OSM_TILE_URL', 'https://tile.openstreetmap.org/{z}/{x}/{y}.png');
    final osmAttr = _envStr('OSM_ATTRIBUTION', '© OpenStreetMap contributors');

    // Combine base markers with selection marker if present
    final List<Marker> displayMarkers = [
      ..._markers,
      if (_selectedPoint != null) _buildSelectionMarker(_selectedPoint!),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(widget.selectionMode ? 'Selecciona ubicación' : 'Mapa de Recordatorios')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: initialZoom,
              onTap: (tapPosition, latLng) {
                if (widget.selectionMode) {
                  setState(() {
                    _selectedPoint = latLng;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
              ),
              MarkerLayer(markers: displayMarkers),
              RichAttributionWidget(
                alignment: AttributionAlignment.bottomRight,
                attributions: [
                  TextSourceAttribution(
                    osmAttr,
                  ),
                ],
              ),
            ],
          ),
          if (widget.selectionMode)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _selectedPoint == null
                          ? null
                          : () {
                              Navigator.pop(context, _selectedPoint);
                            },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Confirmar ubicación'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: widget.selectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                final center = _mapController.camera.center;
                setState(() {
                  _markers.add(_buildMarker(center, 'Nuevo marcador'));
                });
              },
              label: const Text('Añadir marcador'),
              icon: const Icon(Icons.add_location_alt),
            ),
    );
  }
}