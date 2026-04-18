import os
import requests
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required

location_bp = Blueprint('location', __name__)


@location_bp.route('/search', methods=['GET'])
@jwt_required()
def search():
    """Proxy TomTom Fuzzy Search so the API key never leaves the server.

    Env vars:
      TOMTOM_API_KEY       required
      CAMPUS_LAT           optional, default 5.8960 (VVU)
      CAMPUS_LNG           optional, default -0.0940
      LOCATION_RADIUS_M    optional, default 20000
      LOCATION_COUNTRY     optional, default GH
    """
    api_key = os.environ.get('TOMTOM_API_KEY')
    if not api_key:
        return jsonify({'error': 'Location search not configured'}), 503

    query = (request.args.get('q') or '').strip()
    if not query:
        return jsonify({'results': []}), 200

    try:
        limit = int(request.args.get('limit', 5))
    except ValueError:
        limit = 5
    limit = max(1, min(limit, 10))

    lat = os.environ.get('CAMPUS_LAT', '5.8960')
    lng = os.environ.get('CAMPUS_LNG', '-0.0940')
    radius = os.environ.get('LOCATION_RADIUS_M', '20000')
    country = os.environ.get('LOCATION_COUNTRY', 'GH')

    url = f'https://api.tomtom.com/search/2/search/{requests.utils.quote(query)}.json'
    params = {
        'key': api_key,
        'limit': limit,
        'lat': lat,
        'lon': lng,
        'radius': radius,
        'countrySet': country,
    }

    try:
        r = requests.get(url, params=params, timeout=10)
    except requests.RequestException as e:
        return jsonify({'error': f'Location provider unreachable: {e}'}), 502

    if r.status_code != 200:
        return jsonify({'error': 'Location provider error',
                        'status': r.status_code}), 502

    data = r.json() or {}
    raw_results = data.get('results', []) or []

    results = []
    for item in raw_results:
        pos = item.get('position') or {}
        addr = item.get('address') or {}
        poi = item.get('poi') or {}
        label = addr.get('freeformAddress') or poi.get('name') or query
        lat_v = pos.get('lat')
        lng_v = pos.get('lon')
        if lat_v is None or lng_v is None:
            continue
        results.append({
            'address': label,
            'lat': float(lat_v),
            'lng': float(lng_v),
        })

    return jsonify({'results': results}), 200
