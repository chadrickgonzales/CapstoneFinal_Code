import 'dart:convert' as convert;
import 'dart:convert';

import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;


class LocationService {
  final String key = 'AIzaSyAocNg3WkX5ppmhc-vTf1IHvG75EM1Rr5k';


  

  Future<String> getPlaceId(String input) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$input&inputtype=textquery&key=$key';

    var response = await http.get(Uri.parse(url));
    var json = convert.jsonDecode(response.body);
    var placeId = json['candidates'][0]['place_id'] as String;

  

    return placeId;
  }

   Future<Map<String, dynamic>> getPlace(String input) async {
    final placedId = await getPlaceId(input);
    final String url ='https://maps.googleapis.com/maps/api/place/details/json?place_id=$placedId&key=$key';

     var response = await http.get(Uri.parse(url));
    var json = convert.jsonDecode(response.body);
    var results = json['result'] as Map<String, dynamic>;

    print(results);
    return(results);
   }

   Future<Map<String, dynamic>> getDirections(String origin, String destination) async {
    final String url ='https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$key';

     var response = await http.get(Uri.parse(url));
    var json = convert.jsonDecode(response.body);

     if (json['status'] == 'OK') {
      var distance = json['routes'][0]['legs'][0]['distance']['text'];
      var duration = json['routes'][0]['legs'][0]['duration']['text'];

      var results = {
        'bounds_ne': json['routes'][0]['bounds']['northeast'],
        'bounds_sw': json['routes'][0]['bounds']['southwest'],
        'start_location': json['routes'][0]['legs'][0]['start_location'],
        'end_location': json['routes'][0]['legs'][0]['end_location'],
        'polyline': json['routes'][0]['overview_polyline']['points'],
        'polyline_decoded': PolylinePoints().decodePolyline(
            json['routes'][0]['overview_polyline']['points']),
        'distance': distance,
        'duration': duration,
      };

      print(results);

      return results;
    } else {
      throw Exception('Failed to load directions. Status: ${json['status']}');
    }
   }


    Future<Map<String, dynamic>> getPlaceLocation(String placeId) async {
    final url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$key';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final location = json['result']['geometry']['location'];
      return {'lat': location['lat'], 'lng': location['lng']};
    } else {
      throw Exception('Failed to load place location');
    }
  }
}
