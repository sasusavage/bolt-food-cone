from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from sqlalchemy import func
from app import db
from app.models import User

auth_bp = Blueprint('auth', __name__)


def _normalize_email(email):
    return (email or '').strip().lower()


@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.get_json() or {}
    required = ['name', 'email', 'password']
    if not all(k in data and data[k] for k in required):
        return jsonify({'error': 'Missing required fields'}), 400

    email = _normalize_email(data['email'])
    if User.query.filter(func.lower(User.email) == email).first():
        return jsonify({'error': 'Email already registered'}), 409

    user = User(
        name=data['name'].strip(),
        email=email,
        phone=data.get('phone'),
        role='student',
    )
    user.set_password(data['password'])
    db.session.add(user)
    db.session.commit()

    token = create_access_token(identity=str(user.id))
    return jsonify({'token': token, 'user': user.to_dict()}), 201


@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json() or {}
    email = _normalize_email(data.get('email'))
    user = User.query.filter(func.lower(User.email) == email).first()
    if not user or not user.check_password(data.get('password', '')):
        return jsonify({'error': 'Invalid credentials'}), 401

    token = create_access_token(identity=str(user.id))
    return jsonify({'token': token, 'user': user.to_dict()}), 200


@auth_bp.route('/me', methods=['GET'])
@jwt_required()
def me():
    user_id = int(get_jwt_identity())
    user = User.query.get_or_404(user_id)
    return jsonify(user.to_dict()), 200
