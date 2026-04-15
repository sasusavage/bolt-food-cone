from flask import Blueprint, request, jsonify
from app.models import MenuItem

menu_bp = Blueprint('menu', __name__)


@menu_bp.route('/', methods=['GET'])
def get_menu():
    category = request.args.get('category')
    query = MenuItem.query.filter_by(is_available=True)
    if category:
        query = query.filter_by(category=category)
    items = query.all()
    base_url = request.host_url.rstrip('/')
    return jsonify([item.to_dict(base_url) for item in items]), 200


@menu_bp.route('/<int:item_id>', methods=['GET'])
def get_item(item_id):
    item = MenuItem.query.get_or_404(item_id)
    base_url = request.host_url.rstrip('/')
    return jsonify(item.to_dict(base_url)), 200


@menu_bp.route('/categories', methods=['GET'])
def get_categories():
    categories = MenuItem.query.with_entities(MenuItem.category).distinct().all()
    return jsonify([c[0] for c in categories]), 200
