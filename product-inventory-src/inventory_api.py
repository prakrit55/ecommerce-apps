import os
import psycopg2
from psycopg2.extras import RealDictCursor
from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Load database config from environment variables (with defaults)
DB_HOST = os.environ.get('POSTGRES_HOST', 'localhost')
DB_PORT = os.environ.get('POSTGRES_PORT', '5432')
DB_NAME = os.environ.get('POSTGRES_DB', 'postgres')
DB_USER = os.environ.get('POSTGRES_USER', 'postgres')
DB_PASS = os.environ.get('POSTGRES_PASSWORD', 'postgres')

# Default inventory to seed if database is new/empty
default_inventory = [
    {'id': 1, 'quantity': 100},
    {'id': 2, 'quantity': 50},
    {'id': 3, 'quantity': 75},
    {'id': 4, 'quantity': 120},
    {'id': 5, 'quantity': 30},
    {'id': 6, 'quantity': 60},
    {'id': 7, 'quantity': 40},
    {'id': 8, 'quantity': 90},
    {'id': 9, 'quantity': 80},
    {'id': 10, 'quantity': 70},
    {'id': 11, 'quantity': 20},
    {'id': 12, 'quantity': 55}
]

def get_db_connection():
    return psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASS
    )

def init_db():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS inventory (
                id INTEGER PRIMARY KEY,
                quantity INTEGER NOT NULL
            )
        ''')
        conn.commit()
        
        # Check if empty
        cursor.execute('SELECT COUNT(*) FROM inventory')
        count = cursor.fetchone()[0]
        if count == 0:
            for item in default_inventory:
                cursor.execute('INSERT INTO inventory (id, quantity) VALUES (%s, %s)', (item['id'], item['quantity']))
            conn.commit()
        cursor.close()
        conn.close()
        print("Database initialized successfully.")
    except Exception as e:
        print("Failed to initialize database:", e)

# Initialize DB on startup
init_db()

# Get inventory for all products
@app.route('/api/inventory', methods=['GET'])
def get_inventory():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        cursor.execute('SELECT id, quantity FROM inventory')
        rows = cursor.fetchall()
        cursor.close()
        conn.close()
        return jsonify(list(rows))
    except Exception as e:
        print("Error fetching inventory:", e)
        return jsonify({'error': str(e)}), 500

# Get inventory for a single product by ID
@app.route('/api/inventory/<int:product_id>', methods=['GET'])
def get_product_inventory(product_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        cursor.execute('SELECT id, quantity FROM inventory WHERE id = %s', (product_id,))
        row = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if row:
            return jsonify(dict(row))
        else:
            return jsonify({'error': 'Product not found'}), 404
    except Exception as e:
        print("Error fetching product inventory:", e)
        return jsonify({'error': str(e)}), 500

# Reduce the quantity of a product by 1
@app.route('/api/order/<int:product_id>', methods=['POST'])
def order_product(product_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        cursor.execute('SELECT id, quantity FROM inventory WHERE id = %s', (product_id,))
        row = cursor.fetchone()
        
        if not row:
            cursor.close()
            conn.close()
            return jsonify({'error': 'Product not found'}), 404
            
        quantity = row['quantity']
        if quantity > 0:
            new_quantity = quantity - 1
            cursor.execute('UPDATE inventory SET quantity = %s WHERE id = %s', (new_quantity, product_id))
            conn.commit()
            cursor.close()
            conn.close()
            return jsonify({'id': product_id, 'quantity': new_quantity})
        else:
            cursor.close()
            conn.close()
            return jsonify({'error': 'Product is out of stock'}), 400
    except Exception as e:
        print("Error ordering product:", e)
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3002)