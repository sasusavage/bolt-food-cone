import os
import uuid
from datetime import datetime, timedelta
from flask import Blueprint, request, jsonify, current_app
from sqlalchemy import func
from app import db
from app.models import MenuItem, Order, OrderItem, User
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
    return jsonify([o.to_dict(include_user=True) for o in orders]), 200


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
    return jsonify(order.to_dict(include_user=True)), 200


@admin_bp.route('/users', methods=['GET'])
@admin_required
def list_users():
    users = User.query.order_by(User.created_at.desc().nullslast()).all()
    order_counts = dict(
        db.session.query(Order.user_id, func.count(Order.id))
        .group_by(Order.user_id)
        .all()
    )
    out = []
    for u in users:
        d = u.to_dict()
        d['order_count'] = order_counts.get(u.id, 0)
        d['created_at'] = u.created_at.isoformat() if u.created_at else None
        out.append(d)
    return jsonify(out), 200


@admin_bp.route('/stats', methods=['GET'])
@admin_required
def stats():
    now = datetime.utcnow()
    start_of_day = datetime(now.year, now.month, now.day)
    week_ago = now - timedelta(days=7)

    orders_today = (
        Order.query.filter(Order.created_at >= start_of_day).count()
    )
    orders_week = (
        Order.query.filter(Order.created_at >= week_ago).count()
    )
    revenue_today = (
        db.session.query(func.coalesce(func.sum(Order.total_amount), 0))
        .filter(Order.created_at >= start_of_day)
        .filter(Order.status != 'cancelled')
        .scalar()
    )
    revenue_week = (
        db.session.query(func.coalesce(func.sum(Order.total_amount), 0))
        .filter(Order.created_at >= week_ago)
        .filter(Order.status != 'cancelled')
        .scalar()
    )
    pending_orders = Order.query.filter(
        Order.status.in_(['pending', 'confirmed', 'preparing', 'out_for_delivery'])
    ).count()
    total_users = User.query.count()
    total_items = MenuItem.query.count()
    out_of_stock = MenuItem.query.filter(MenuItem.stock <= 0).count()

    popular_rows = (
        db.session.query(
            MenuItem.id,
            MenuItem.name,
            func.coalesce(func.sum(OrderItem.quantity), 0).label('qty'),
        )
        .outerjoin(OrderItem, OrderItem.menu_item_id == MenuItem.id)
        .outerjoin(Order, Order.id == OrderItem.order_id)
        .filter((Order.created_at == None) | (Order.created_at >= week_ago))  # noqa
        .group_by(MenuItem.id, MenuItem.name)
        .order_by(func.sum(OrderItem.quantity).desc().nullslast())
        .limit(5)
        .all()
    )
    popular = [
        {'id': r.id, 'name': r.name, 'sold': int(r.qty or 0)}
        for r in popular_rows
    ]

    status_rows = (
        db.session.query(Order.status, func.count(Order.id))
        .group_by(Order.status)
        .all()
    )
    status_breakdown = {s: c for s, c in status_rows}

    return jsonify({
        'orders_today': orders_today,
        'orders_week': orders_week,
        'revenue_today': float(revenue_today or 0),
        'revenue_week': float(revenue_week or 0),
        'pending_orders': pending_orders,
        'total_users': total_users,
        'total_items': total_items,
        'out_of_stock': out_of_stock,
        'popular_items': popular,
        'status_breakdown': status_breakdown,
    }), 200


@admin_bp.route('/categories', methods=['GET'])
@admin_required
def list_categories():
    rows = (
        db.session.query(
            MenuItem.category,
            func.count(MenuItem.id),
        )
        .group_by(MenuItem.category)
        .order_by(MenuItem.category)
        .all()
    )
    return jsonify([
        {'name': name, 'item_count': count}
        for name, count in rows
    ]), 200


@admin_bp.route('/categories/rename', methods=['POST'])
@admin_required
def rename_category():
    data = request.get_json() or {}
    old_name = (data.get('old') or '').strip()
    new_name = (data.get('new') or '').strip()
    if not old_name or not new_name:
        return jsonify({'error': 'old and new category names are required'}), 400
    updated = (
        MenuItem.query.filter(MenuItem.category == old_name)
        .update({MenuItem.category: new_name}, synchronize_session=False)
    )
    db.session.commit()
    return jsonify({'updated': updated, 'old': old_name, 'new': new_name}), 200
