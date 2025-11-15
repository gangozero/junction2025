/// Fullscreen map screen
library;

import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre/maplibre.dart';

import '../../../device/domain/entities/sauna_controller.dart';
import '../../../dashboard/presentation/providers/device_list_provider.dart';

enum MetricType { temperature, humidity, time }

/// Fullscreen map screen showing device locations
///
/// Displays a map with markers for all devices that have location data
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  // Style + images ready
  bool _styleReady = false;
  MapController? _mapController;
  StyleController? _styleController;
  // Cached feature lists so we can rebuild layers after style load
  List<Feature<Point>> _controllerPoints = [];
  List<Feature<Point>> _sensorPoints = [];
  // Random weights maps for each metric type (8-20 inclusive)
  late final Map<int, int> _temperatureWeights;
  late final Map<int, int> _humidityWeights;
  late final Map<int, int> _timeWeights;
  // Current selected metric
  MetricType _selectedMetric = MetricType.temperature;
  // Track if style is loaded
  bool _styleLoaded = false;

  @override
  void initState() {
    super.initState();
    developer.log('[Map] MapScreen initState', name: 'HarviaMSGA');
    _temperatureWeights = _generateRandomWeights();
    _humidityWeights = _generateRandomWeights();
    _timeWeights = _generateRandomWeights();
  }

  /// Generate random weights (8-20 inclusive) for region IDs 0-335
  Map<int, int> _generateRandomWeights() {
    final random = math.Random();
    final weights = <int, int>{};
    for (int id = 0; id <= 335; id++) {
      weights[id] = 8 + random.nextInt(13); // 8-20 inclusive
    }
    developer.log(
      '[Map] Generated ${weights.length} random weights (sample: ${weights.entries.take(5).map((e) => '${e.key}:${e.value}').join(', ')})',
      name: 'HarviaMSGA',
    );
    return weights;
  }

  /// Build gradient expression for red (temperature)
  List<dynamic> _buildRedGradient(Map<int, int> weights) {
    return [
      'interpolate',
      ['linear'],
      ['id'],
      ...weights.entries.expand((entry) {
        final id = entry.key;
        final weight = entry.value;
        final redValue = 255 - ((weight - 8) * 116 ~/ 12);
        final greenBlueValue = 200 - ((weight - 8) * 200 ~/ 12);
        final color =
            '#${redValue.toRadixString(16).padLeft(2, '0')}${greenBlueValue.toRadixString(16).padLeft(2, '0')}${greenBlueValue.toRadixString(16).padLeft(2, '0')}';
        return [id, color];
      }).toList(),
    ];
  }

  /// Build gradient expression for blue (humidity)
  List<dynamic> _buildBlueGradient(Map<int, int> weights) {
    return [
      'interpolate',
      ['linear'],
      ['id'],
      ...weights.entries.expand((entry) {
        final id = entry.key;
        final weight = entry.value;
        final blueValue = 255 - ((weight - 8) * 116 ~/ 12);
        final redGreenValue = 200 - ((weight - 8) * 200 ~/ 12);
        final color =
            '#${redGreenValue.toRadixString(16).padLeft(2, '0')}${redGreenValue.toRadixString(16).padLeft(2, '0')}${blueValue.toRadixString(16).padLeft(2, '0')}';
        return [id, color];
      }).toList(),
    ];
  }

  /// Build gradient expression for green (time)
  List<dynamic> _buildGreenGradient(Map<int, int> weights) {
    return [
      'interpolate',
      ['linear'],
      ['id'],
      ...weights.entries.expand((entry) {
        final id = entry.key;
        final weight = entry.value;
        final greenValue = 255 - ((weight - 8) * 116 ~/ 12);
        final redBlueValue = 200 - ((weight - 8) * 200 ~/ 12);
        final color =
            '#${redBlueValue.toRadixString(16).padLeft(2, '0')}${greenValue.toRadixString(16).padLeft(2, '0')}${redBlueValue.toRadixString(16).padLeft(2, '0')}';
        return [id, color];
      }).toList(),
    ];
  }

  /// Update the layer color based on selected metric
  Future<void> _updateLayerColor(StyleController style) async {
    try {
      // Remove existing layer
      await style.removeLayer('regions-layer');

      // Build appropriate gradient based on selected metric
      final gradientExpression = switch (_selectedMetric) {
        MetricType.temperature => _buildRedGradient(_temperatureWeights),
        MetricType.humidity => _buildBlueGradient(_humidityWeights),
        MetricType.time => _buildGreenGradient(_timeWeights),
      };

      // Add layer with new color
      await style.addLayer(
        FillStyleLayer(
          id: 'regions-layer',
          sourceId: 'regions-source',
          paint: {'fill-color': gradientExpression, 'fill-opacity': 0.5},
        ),
      );

      developer.log(
        '[Map] ✅ Updated layer color for metric: $_selectedMetric',
        name: 'HarviaMSGA',
      );
    } catch (e, stack) {
      developer.log(
        '[Map] ❌ Error updating layer color',
        name: 'HarviaMSGA',
        error: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceListAsync = ref.watch(deviceListProvider);

    // WORKAROUND: Local asset 'assets/colorful.json' not firing MapEventStyleLoaded
    // Using remote URL until asset loading issue is resolved
    const styleUrl =
        'https://pnorman.github.io/tilekiln-shortbread-demo/colorful.json';
    developer.log('[Map] Building with style: $styleUrl', name: 'HarviaMSGA');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Löyly Atlas'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: deviceListAsync.when(
        data: (devices) {
          // Build point lists (recomputed each build; kept also in state for styleReady rebuild)
          final newControllerPoints = <Feature<Point>>[];
          final newSensorPoints = <Feature<Point>>[];

          for (final device in devices) {
            final location = _getDeviceLocation(device);
            if (location == null) continue;
            final feature = Feature<Point>(
              id: device.deviceId,
              geometry: Point(location),
            );
            if (device.deviceType == DeviceType.fenix) {
              newControllerPoints.add(feature);
            } else {
              newSensorPoints.add(feature);
            }
          }

          // Update cached lists if different counts (avoid unnecessary rebuild spam)
          if (newControllerPoints.length != _controllerPoints.length ||
              newSensorPoints.length != _sensorPoints.length) {
            _controllerPoints = newControllerPoints;
            _sensorPoints = newSensorPoints;

            // Log coordinates for debugging
            developer.log(
              '[Map] 📍 Markers: ${_controllerPoints.length} controllers, ${_sensorPoints.length} sensors',
              name: 'HarviaMSGA',
            );
          }

          return Stack(
            children: [
              MapLibreMap(
                options: const MapOptions(
                  initCenter: Geographic(lon: 24.629913, lat: 60.156773),
                  initZoom: 9.0,
                  initStyle: styleUrl,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  developer.log(
                    '[Map] MapLibreMap created',
                    name: 'HarviaMSGA',
                  );
                },
                onStyleLoaded: (style) async {
                  _styleController = style;
                  try {
                    // Fetch the remote GeoJSON data
                    const geoJsonUrl =
                        'https://raw.githubusercontent.com/varmais/maakunnat/refs/heads/master/kunnat.geojson';
                    final response = await http.get(Uri.parse(geoJsonUrl));
                    if (response.statusCode != 200) {
                      throw Exception(
                        'Failed to load GeoJSON: ${response.statusCode}',
                      );
                    }
                    final geoJsonData = response.body;
                    developer.log(
                      '[Map] ✅ GeoJSON fetched successfully',
                      name: 'HarviaMSGA',
                    );

                    // Add the GeoJSON source
                    await style.addSource(
                      GeoJsonSource(id: 'regions-source', data: geoJsonData),
                    );
                    developer.log(
                      '[Map] ✅ GeoJSON source added',
                      name: 'HarviaMSGA',
                    );

                    // Add the fill layer with temperature gradient (red)
                    final interpolateExpression = _buildRedGradient(
                      _temperatureWeights,
                    );

                    await style.addLayer(
                      FillStyleLayer(
                        id: 'regions-layer',
                        sourceId: 'regions-source',
                        paint: {
                          'fill-color': interpolateExpression,
                          'fill-opacity': 0.5,
                        },
                      ),
                    );

                    setState(() {
                      _styleLoaded = true;
                    });

                    developer.log(
                      '[Map] ✅ GeoJSON fill layer added with temperature gradient',
                      name: 'HarviaMSGA',
                    );
                  } catch (e, stack) {
                    developer.log(
                      '[Map] ❌ Error adding GeoJSON layer',
                      name: 'HarviaMSGA',
                      error: e,
                      stackTrace: stack,
                    );
                  }
                },
                onEvent: (event) async {
                  developer.log(
                    '[Map] Event: ${event.runtimeType}',
                    name: 'HarviaMSGA',
                  );

                  if (event is MapEventStyleLoaded) {
                    developer.log(
                      '[Map] ✅ Style loaded successfully',
                      name: 'HarviaMSGA',
                    );

                    try {
                      // Load icon images once style is ready - make them HUGE
                      await event.style.addImageFromIconData(
                        id: 'controller-marker',
                        iconData: Icons.thermostat,
                        color: Colors.red,
                        size: 64, // Explicit large pixel size
                      );
                      await event.style.addImageFromIconData(
                        id: 'sensor-marker',
                        iconData: Icons.sensors,
                        color: Colors.blue,
                        size: 64, // Explicit large pixel size
                      );

                      developer.log(
                        '[Map] ✅ Icons registered: controller-marker (red), sensor-marker (blue)',
                        name: 'HarviaMSGA',
                      );

                      if (!_styleReady) {
                        developer.log(
                          '[Map] Markers ready - Controllers: ${_controllerPoints.length}, '
                          'Sensors: ${_sensorPoints.length}',
                          name: 'HarviaMSGA',
                        );
                        setState(() => _styleReady = true);

                        // Fit camera to show all markers
                        await _fitBoundsToMarkers();
                      }
                    } catch (e, stack) {
                      developer.log(
                        '[Map] ❌ Error loading icons',
                        name: 'HarviaMSGA',
                        error: e,
                        stackTrace: stack,
                      );
                    }
                  }
                },
                layers: _styleReady
                    ? [
                        if (_controllerPoints.isNotEmpty)
                          MarkerLayer(
                            points: _controllerPoints,
                            iconImage: 'controller-marker',
                            iconSize: 1.5, // Scale multiplier
                            iconAnchor: IconAnchor.center,
                            iconAllowOverlap: true,
                            iconIgnorePlacement: true,
                          ),
                        if (_sensorPoints.isNotEmpty)
                          MarkerLayer(
                            points: _sensorPoints,
                            iconImage: 'sensor-marker',
                            iconSize: 1.5, // Scale multiplier
                            iconAnchor: IconAnchor.center,
                            iconAllowOverlap: true,
                            iconIgnorePlacement: true,
                          ),
                      ]
                    : const [],
              ),
              // Map controls
              Positioned(
                right: 16,
                bottom: 110,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'zoom_in',
                      onPressed: () async {
                        final camera = await _mapController?.getCamera();
                        if (camera != null) {
                          await _mapController?.animateCamera(
                            zoom: camera.zoom + 1,
                          );
                        }
                      },
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'zoom_out',
                      onPressed: () async {
                        final camera = await _mapController?.getCamera();
                        if (camera != null) {
                          await _mapController?.animateCamera(
                            zoom: camera.zoom - 1,
                          );
                        }
                      },
                      child: const Icon(Icons.remove),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'my_location',
                      onPressed: () {
                        _mapController?.animateCamera(
                          center: const Geographic(
                            lon: 24.629913,
                            lat: 60.156773,
                          ),
                          zoom: 14.0,
                        );
                      },
                      child: const Icon(Icons.my_location),
                    ),
                  ],
                ),
              ),
              // Metric selector at bottom
              if (_styleLoaded)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _MetricButton(
                        icon: Icons.thermostat,
                        label: 'Temp',
                        isSelected: _selectedMetric == MetricType.temperature,
                        onTap: () async {
                          if (_selectedMetric != MetricType.temperature) {
                            setState(() {
                              _selectedMetric = MetricType.temperature;
                            });
                            final style = _styleController;
                            if (style != null) {
                              await _updateLayerColor(style);
                            }
                          }
                        },
                      ),
                      _MetricButton(
                        icon: Icons.water_drop,
                        label: 'Humidity',
                        isSelected: _selectedMetric == MetricType.humidity,
                        onTap: () async {
                          if (_selectedMetric != MetricType.humidity) {
                            setState(() {
                              _selectedMetric = MetricType.humidity;
                            });
                            final style = _styleController;
                            if (style != null) {
                              await _updateLayerColor(style);
                            }
                          }
                        },
                      ),
                      _MetricButton(
                        icon: Icons.access_time,
                        label: 'Time',
                        isSelected: _selectedMetric == MetricType.time,
                        onTap: () async {
                          if (_selectedMetric != MetricType.time) {
                            setState(() {
                              _selectedMetric = MetricType.time;
                            });
                            final style = _styleController;
                            if (style != null) {
                              await _updateLayerColor(style);
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error loading map'),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Geographic? _getDeviceLocation(SaunaController device) {
    // For demo purposes, return mock locations
    // In production, parse latitude/longitude from device attributes

    // Mock locations in Finland area (lon, lat order)
    // One controller (fd1d00ba) and one sensor (66db1620) near Helsinki center for testing
    final mockLocations = {
      'a510367c-a839-4216-86a7-5a85d57e5219': const Geographic(
        lon: 24.9384,
        lat: 60.1699,
      ),
      '87cb696a-3235-4909-9eeb-dba5f96cdb64': const Geographic(
        lon: 25.6479,
        lat: 62.1036,
      ),
      '7772e2d7-6632-4941-94bd-ec0d403f68ae': const Geographic(
        lon: 23.7610,
        lat: 61.4978,
      ),
      // Sensor near Helsinki center (60.156773, 24.629913)
      '66db1620-014b-4575-a4cc-e11e0de27d14': const Geographic(
        lon: 24.630500,
        lat: 60.157200,
      ),
      'febb62d5-55f4-49cd-b481-93638a0ae41d': const Geographic(
        lon: 25.4651,
        lat: 65.0121,
      ),
      '82aa4055-11ca-47ef-a1c5-a90cf931a1e0': const Geographic(
        lon: 27.7253,
        lat: 64.2208,
      ),
      '51753849-A9C4-4D03-BA02-CEE8B494F621': const Geographic(
        lon: 24.9384,
        lat: 60.1699,
      ),
      // Controller near Helsinki center (60.156773, 24.629913)
      'fd1d00ba-ac1d-4340-8c81-8ef2e55780b3': const Geographic(
        lon: 24.630500,
        lat: 60.157200,
      ),
      '5581823b-d353-40c2-9498-1c1b879b5061': const Geographic(
        lon: 28.1887,
        lat: 61.0587,
      ),
      '7ac12516-d915-49ae-a296-30f5fc6fb881': const Geographic(
        lon: 27.6784,
        lat: 62.8924,
      ),
      '7fbd8051-c339-4302-9de5-016c3a7dba90': const Geographic(
        lon: 23.1316,
        lat: 63.8467,
      ),
    };

    return mockLocations[device.deviceId];
  }

  /// Fit camera bounds to show all markers
  Future<void> _fitBoundsToMarkers() async {
    if (_mapController == null) return;

    // Collect all device locations directly
    final deviceListAsync = ref.read(deviceListProvider);
    final devices = deviceListAsync.valueOrNull;
    if (devices == null || devices.isEmpty) return;

    final locations = <Geographic>[];
    for (final device in devices) {
      final loc = _getDeviceLocation(device);
      if (loc != null) {
        locations.add(loc);
      }
    }

    if (locations.isEmpty) return;

    // Calculate bounds
    double minLon = locations.first.lon;
    double maxLon = locations.first.lon;
    double minLat = locations.first.lat;
    double maxLat = locations.first.lat;

    for (final loc in locations) {
      if (loc.lon < minLon) minLon = loc.lon;
      if (loc.lon > maxLon) maxLon = loc.lon;
      if (loc.lat < minLat) minLat = loc.lat;
      if (loc.lat > maxLat) maxLat = loc.lat;
    }

    // Calculate center and rough zoom
    final centerLon = (minLon + maxLon) / 2;
    final centerLat = (minLat + maxLat) / 2;
    final lonDiff = maxLon - minLon;
    final latDiff = maxLat - minLat;
    final maxDiff = lonDiff > latDiff ? lonDiff : latDiff;

    // Rough zoom calculation (lower zoom = more area visible)
    double zoom = 9.0;
    if (maxDiff > 10) {
      zoom = 4.0;
    } else if (maxDiff > 5) {
      zoom = 5.0;
    } else if (maxDiff > 2) {
      zoom = 6.0;
    } else if (maxDiff > 1) {
      zoom = 7.0;
    }

    developer.log(
      '[Map] 📐 Fitting ${locations.length} markers: lon[${minLon.toStringAsFixed(2)}, ${maxLon.toStringAsFixed(2)}], '
      'lat[${minLat.toStringAsFixed(2)}, ${maxLat.toStringAsFixed(2)}], '
      'center=(${centerLon.toStringAsFixed(2)}, ${centerLat.toStringAsFixed(2)}), zoom=$zoom',
      name: 'HarviaMSGA',
    );

    await _mapController!.animateCamera(
      center: Geographic(lon: centerLon, lat: centerLat),
      zoom: zoom,
    );
  }
}

/// Button widget for metric selection
class _MetricButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MetricButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
