from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models import MenuItem, Order, OrderItem
from sqlalchemy.exc import SQLAlchemyError

orders_bp = Blueprint('orders', __name__)


@orders_bp.route('/place', methods=['POST'])
@jwt_required()
def place_order():
    """
    Atomic order placement with stock validation.
    Body: {
        "items": [{"menu_item_id": 1, "quantity": 2}, ...],
        "delivery_address": "Block A, VVU",
        "delivery_lat": 5.6037,
        "delivery_lng": -0.1870,
        "notes": "Extra spicy"
    }
    """
    user_id = int(get_jwt_identity())
    data = request.get_json()

    cart_items = data.get('items', [])
    if not cart_items:
        return jsonify({'error': 'Cart is empty'}), 400

    try:
        # Step 1: Lock and validate ALL items before any mutation
        resolved = []
        for cart_item in cart_items:
            item_id = cart_item.get('menu_item_id')
            qty = cart_item.get('quantity', 0)

            if qty <= 0:
                return jsonify({'error': f'Invalid quantity for item {item_id}'}), 400

            # SELECT FOR UPDATE — row-level lock for this transaction
            menu_item = (
                MenuItem.query
                .filter_by(id=item_id, is_available=True)
                .with_for_update()
                .first()
            )

            if not menu_item:
                db.session.rollback()
                return jsonify({'error': f'Menu item {item_id} not found or unavailable'}), 404

            if menu_item.stock < qty:
                db.session.rollback()
                return jsonify({
                    'error': f'Insufficient stock for "{menu_item.name}". '
                             f'Available: {menu_item.stock}, Requested: {qty}'
                }), 409

            resolved.append({'item': menu_item, 'quantity': qty})

        # Step 2: All checks passed — decrement stock and create records
        total = 0.0
        order_items = []

        for r in resolved:
            menu_item = r['item']
            qty = r['quantity']
            menu_item.stock -= qty
            subtotal = float(menu_item.price) * qty
            total += subtotal
            order_items.append(OrderItem(
                menu_item_id=menu_item.id,
                quantity=qty,
                unit_price=menu_item.price,
            ))

        order = Order(
            user_id=user_id,
            total_amount=round(total, 2),
            delivery_address=data.get('delivery_address'),
            delivery_lat=data.get('delivery_lat'),
            delivery_lng=data.get('delivery_lng'),
            notes=data.get('notes'),
            status='pending',
        )
        db.session.add(order)
        db.session.flush()  # get order.id before commit

        for oi in order_items:
            oi.order_id = order.id
            db.session.add(oi)

        db.session.commit()

        return jsonify({'message': 'Order placed successfully', 'order': order.to_dict()}), 201

    except SQLAlchemyError:
        db.session.rollback()
        return jsonify({'error': 'Database error. Please try again.'}), 500


@orders_bp.route('/my-orders', methods=['GET'])
@jwt_required()
def my_orders():
    user_id = int(get_jwt_identity())
    orders = Order.query.filter_by(user_id=user_id).order_by(Order.created_at.desc()).all()
    return jsonify([o.to_dict() for o in orders]), 200


@orders_bp.route('/<int:order_id>', methods=['GET'])
@jwt_required()
def get_order(order_id):
    user_id = int(get_jwt_identity())
    order = Order.query.filter_by(id=order_id, user_id=user_id).first_or_404()
    return jsonify(order.to_dict()), 200
