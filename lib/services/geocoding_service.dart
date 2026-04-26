import 'dart:convert';
import 'package:http/http.dart' as http;



class GeocodingResult{
  final String addressText;
  final String district;

  GeocodingResult({
    required this.addressText,
    required this.district,
  });
}

class GeocodingService {
  Future<GeocodingResult?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async{
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?format=jsonv2'
      '&lat=$latitude'
      '&lon=$longitude'
      '&addressdetails=1'
      '&accept-language=ru',
    );

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': 'findBack-course-project/1.0',
      },
    );

    if(response.statusCode != 200){
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final address = data['address'] as Map<String, dynamic>?;

    final addressText = data['display_name'] as String? ?? '';

    final district = 
        address?['city_district'] as String? ??
        address?['suburb'] as String? ??
        address?['borough'] as String? ??
        address?['county'] as String? ??
        address?['city'] as String? ??
        address?['town'] as String? ??
        address?['village'] as String? ??
        'Другой';

    return GeocodingResult(addressText: addressText, district: district);  
    
  }
}