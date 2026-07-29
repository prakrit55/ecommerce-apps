import os
import psycopg2
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
            CREATE TABLE IF NOT EXISTS contact_submissions (
                id SERIAL PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                email VARCHAR(255) NOT NULL,
                subject VARCHAR(255),
                message TEXT NOT NULL,
                submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        conn.commit()
        cursor.close()
        conn.close()
        print("Contact support database initialized successfully.")
    except Exception as e:
        print("Failed to initialize contact support database:", e)

# Initialize DB on startup
init_db()

@app.route('/api/contact-message', methods=['GET'])
def get_contact_message():
    response = {
        'message': "We're here to help! If you have any questions, concerns, or feedback, please don't hesitate to reach out to us. Our dedicated support team is ready to assist you."
    }
    return jsonify(response)

@app.route('/api/contact-submit', methods=['POST'])
def submit_contact_form():
    try:
        post_data = request.get_json()
        print("Received submission:", post_data)
        
        name = post_data.get('name', '')
        email = post_data.get('email', '')
        subject = post_data.get('subject', '')
        message = post_data.get('message', '')

        if not name or not email or not message:
            return jsonify({'error': 'Name, email, and message are required'}), 400

        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute('''
            INSERT INTO contact_submissions (name, email, subject, message)
            VALUES (%s, %s, %s, %s)
        ''', (name, email, subject, message))
        conn.commit()
        cursor.close()
        conn.close()

        response = {'status': 'success', 'message': 'Your message has been successfully submitted.'}
        return jsonify(response)
    except Exception as e:
        print("Error submitting contact form:", e)
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)