import os
import uuid
from flask import Blueprint, request, jsonify, current_app
from app import db
from app.models import MenuItem, Order, User
from app.decorators import admin_required
from werkzeug.utils import secure_filename

admin_bp = Blueprint('admin', __name__)

ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'webp'}


def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


@admin_bp.route('/menu', methods=['POST'])
@admin_required
def create_menu_item():
    name = request.form.get('name')
    price = request.form.get('price')
    category = request.form.get('category')
    stock = request.form.get('stock', 0)

    if not all([name, price, category]):
        return jsonify({'error': 'name, price, category are required'}), 400

    image_filename = None
    if 'image' in request.files:
        file = request.files['image']
        if file and allowed_file(file.filename):
            ext = file.filename.rsplit('.', 1)[1].lower()
            image_filename = f"{uuid.uuid4().hex}.{ext}"
            save_path = os.path.join(current_app.config['UPLOAD_FOLDER'], image_filename)
            os.makedirs(os.path.dirname(save_path), exist_ok=True)
            file.save(save_path)

    item = MenuItem(
        name=name,
        description=request.form.get('description'),
        price=float(price),
        category=category,
        stock=int(stock),
        image_filename=image_filename,
    )
    db.session.add(item)
    db.session.commit()

    base_url = request.host_url.rstrip('/')
    return jsonify(item.to_dict(base_url)), 201


@admin_bp.route('/menu/<int:item_id>', methods=['PATCH'])
@admin_required
def update_menu_item(item_id):
    item = MenuItem.query.get_or_404(item_id)
    data = request.get_json()
    for field in ['name', 'description', 'price', 'category', 'stock', 'is_available']:
        if field in data:
            setattr(item, field, data[field])
    db.session.commit()
    base_url = request.host_url.rstrip('/')
    return jsonify(item.to_dict(base_url)), 200


@admin_bp.route('/menu/<int:item_id>/image', methods=['POST'])
@admin_required
def update_menu_image(item_id):
    item = MenuItem.query.get_or_404(item_id)
    if 'image' not in request.files:
        return jsonify({'error': 'No image provided'}), 400
    file = request.files['image']
    if not allowed_file(file.filename):
        return jsonify({'error': 'Invalid file type. Allowed: png, jpg, jpeg, webp'}), 400
    ext = file.filename.rsplit('.', 1)[1].lower()
    image_filename = f"{uuid.uuid4().hex}.{ext}"
    save_path = os.path.join(current_app.config['UPLOAD_FOLDER'], image_filename)
    os.makedirs(os.path.dirname(save_path), exist_ok=True)
    file.save(save_path)
    if item.image_filename:
        old_path = os.path.join(current_app.config['UPLOAD_FOLDER'], item.image_filename)
        if os.path.exists(old_path):
            os.remove(old_path)
    item.image_filename = image_filename
    db.session.commit()
    base_url = request.host_url.rstrip('/')
    return jsonify(item.to_dict(base_url)), 200


@admin_bp.route('/menu/<int:item_id>', methods=['DELETE'])
@admin_required
def delete_menu_item(item_id):
    item = MenuItem.query.get_or_404(item_id)
    db.session.delete(item)
    db.session.commit()
    return jsonify({'message': 'Deleted'}), 200


@admin_bp.route('/orders', methods=['GET'])
@admin_required
def all_orders():
    orders = Order.query.order_by(Order.created_at.desc()).all()
    return jsonify([o.to_dict() for o in orders]), 200


@admin_bp.route('/orders/<int:order_id>/status', methods=['PATCH'])
@admin_required
def update_order_status(order_id):
    order = Order.query.get_or_404(order_id)
    data = request.get_json()
    valid_statuses = ['pending', 'confirmed', 'preparing', 'out_for_delivery', 'delivered', 'cancelled']
    new_status = data.get('status')
    if new_status not in valid_statuses:
        return jsonify({'error': f'Invalid status. Must be one of: {valid_statuses}'}), 400
    order.status = new_status
    db.session.commit()
    return jsonify(order.to_dict()), 200


@admin_bp.route('/users', methods=['GET'])
@admin_required
def list_users():
    users = User.query.all()
    return jsonify([u.to_dict() for u in users]), 200
