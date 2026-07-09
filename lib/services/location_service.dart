import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class LocationService {
  static const String _placesApiKey =
      'YOUR_API_KEY_HERE'; // User should add their key
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';

  static Future<List<LocationSuggestion>> getLocationSuggestions(
      String input) async {
    if (input.isEmpty) return [];

    // Check if API key is set
    if (_placesApiKey == 'YOUR_API_KEY_HERE' || _placesApiKey.isEmpty) {
      print(
          'Google Places API key not configured. Please set your API key in location_service.dart');
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl?input=$input&key=$_placesApiKey&components=country:pk|country:in'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          return predictions
              .map((prediction) => LocationSuggestion.fromJson(prediction))
              .toList();
        }
      }
    } catch (e) {
      print('Error fetching location suggestions: $e');
    }

    return [];
  }

  static Future<LocationDetails?> getPlaceDetails(String placeId) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_placesApiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return LocationDetails.fromJson(data['result']);
        }
      }
    } catch (e) {
      print('Error fetching place details: $e');
    }

    return null;
  }
}

class LocationSuggestion {
  final String description;
  final String placeId;
  final List<String> terms;

  LocationSuggestion({
    required this.description,
    required this.placeId,
    required this.terms,
  });

  factory LocationSuggestion.fromJson(Map<String, dynamic> json) {
    return LocationSuggestion(
      description: json['description'] ?? '',
      placeId: json['place_id'] ?? '',
      terms: (json['terms'] as List?)
              ?.map((term) => term['value'] as String)
              .toList() ??
          [],
    );
  }
}

class LocationDetails {
  final String formattedAddress;
  final double lat;
  final double lng;
  final String phoneNumber;
  final String website;

  LocationDetails({
    required this.formattedAddress,
    required this.lat,
    required this.lng,
    this.phoneNumber = '',
    this.website = '',
  });

  factory LocationDetails.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] ?? {};
    final location = geometry['location'] ?? {};

    return LocationDetails(
      formattedAddress: json['formatted_address'] ?? '',
      lat: (location['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (location['lng'] as num?)?.toDouble() ?? 0.0,
      phoneNumber: json['formatted_phone_number'] ?? '',
      website: json['website'] ?? '',
    );
  }
}

class LocationAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final Function(LocationDetails) onLocationSelected;
  final String? hintText;

  const LocationAutocomplete({
    required this.controller, required this.onLocationSelected, super.key,
    this.hintText,
  });

  @override
  State<LocationAutocomplete> createState() => _LocationAutocompleteState();
}

class _LocationAutocompleteState extends State<LocationAutocomplete> {
  List<LocationSuggestion> _suggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    if (text.length >= 2) {
      _fetchSuggestions(text);
    } else {
      setState(() {
        _suggestions.clear();
      });
    }
  }

  Future<void> _fetchSuggestions(String input) async {
    setState(() {
      _isLoading = true;
    });

    final suggestions = await LocationService.getLocationSuggestions(input);

    if (mounted) {
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectSuggestion(LocationSuggestion suggestion) async {
    widget.controller.text = suggestion.description;
    setState(() {
      _suggestions.clear();
    });

    final details = await LocationService.getPlaceDetails(suggestion.placeId);
    if (details != null) {
      widget.onLocationSelected(details);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            hintText: widget.hintText ?? 'Enter location',
            border: const OutlineInputBorder(),
            suffixIcon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.location_on),
          ),
        ),
        if (_suggestions.isNotEmpty)
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ListView.builder(
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on, size: 20),
                  title: Text(
                    suggestion.description,
                    style: const TextStyle(fontSize: 14),
                  ),
                  onTap: () => _selectSuggestion(suggestion),
                );
              },
            ),
          ),
      ],
    );
  }
}
