import os
import json
import boto3
import psycopg2
import jwt
from datetime import datetime
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# ── database init ──────────────────────────────────────────────────────────

app = Flask(__name__)
CORS(app)

# ── Database init ─────────────────────────────────────────────────────────────

def init_db():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS entries (
                id SERIAL PRIMARY KEY,
                user_id VARCHAR(255) NOT NULL,
                entry_date DATE NOT NULL,
                description TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        conn.commit()
        cur.close()
        conn.close()
        print("Database initialized successfully")
    except Exception as e:
        print(f"DB init error: {e}")
        raise

# ── Database connection ───────────────────────────────────────────────────────

def get_db_connection():
    return psycopg2.connect(
        host=os.environ.get('DB_HOST'),
        database=os.environ.get('DB_NAME', 'dailylog'),
        user=os.environ.get('DB_USER'),
        password=os.environ.get('DB_PASSWORD')
    )

# ── Cognito token validation ──────────────────────────────────────────────────

def get_user_id(request):
    token = request.headers.get('Authorization', '').replace('Bearer ', '')
    if not token:
        return None
    try:
        # Decode without verification here — API Gateway already validated it
        decoded = jwt.decode(token, options={"verify_signature": False})
        return decoded.get('sub')  # Cognito user ID
    except Exception:
        return None

def require_auth(f):
    from functools import wraps
    @wraps(f)
    def decorated(*args, **kwargs):
        user_id = get_user_id(request)
        if not user_id:
            return jsonify({'error': 'Unauthorized'}), 401
        return f(user_id, *args, **kwargs)
    return decorated

# ── Routes ────────────────────────────────────────────────────────────────────

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy'}), 200


@app.route('/entries', methods=['GET'])
@require_auth
def get_entries(user_id):
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(
        """
        SELECT id, entry_date, description, created_at
        FROM entries
        WHERE user_id = %s
        ORDER BY entry_date DESC
        """,
        (user_id,)
    )
    rows = cur.fetchall()
    cur.close()
    conn.close()

    entries = [
        {
            'id': row[0],
            'date': row[1].isoformat(),
            'description': row[2],
            'created_at': row[3].isoformat()
        }
        for row in rows
    ]
    return jsonify(entries), 200


@app.route('/entries', methods=['POST'])
@require_auth
def create_entry(user_id):
    data = request.get_json()
    if not data or not data.get('date') or not data.get('description'):
        return jsonify({'error': 'date and description are required'}), 400

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(
        """
        INSERT INTO entries (user_id, entry_date, description)
        VALUES (%s, %s, %s)
        RETURNING id, entry_date, description, created_at
        """,
        (user_id, data['date'], data['description'])
    )
    row = cur.fetchone()
    conn.commit()
    cur.close()
    conn.close()

    return jsonify({
        'id': row[0],
        'date': row[1].isoformat(),
        'description': row[2],
        'created_at': row[3].isoformat()
    }), 201


@app.route('/entries/<int:entry_id>', methods=['PUT'])
@require_auth
def update_entry(user_id, entry_id):
    data = request.get_json()
    if not data or not data.get('description'):
        return jsonify({'error': 'description is required'}), 400

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(
        """
        UPDATE entries
        SET description = %s, updated_at = %s
        WHERE id = %s AND user_id = %s
        RETURNING id, entry_date, description, updated_at
        """,
        (data['description'], datetime.utcnow(), entry_id, user_id)
    )
    row = cur.fetchone()
    conn.commit()
    cur.close()
    conn.close()

    if not row:
        return jsonify({'error': 'Entry not found'}), 404

    return jsonify({
        'id': row[0],
        'date': row[1].isoformat(),
        'description': row[2],
        'updated_at': row[3].isoformat()
    }), 200


@app.route('/entries/<int:entry_id>', methods=['DELETE'])
@require_auth
def delete_entry(user_id, entry_id):
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(
        "DELETE FROM entries WHERE id = %s AND user_id = %s RETURNING id",
        (entry_id, user_id)
    )
    row = cur.fetchone()
    conn.commit()
    cur.close()
    conn.close()

    if not row:
        return jsonify({'error': 'Entry not found'}), 404

    return jsonify({'message': 'Entry deleted'}), 200


# ── Run ───────────────────────────────────────────────────────────────────────
init_db()
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

