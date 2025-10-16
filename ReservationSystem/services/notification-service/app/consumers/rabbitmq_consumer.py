import pika
import json
import os
from app.utils.email_sender import send_email

RABBITMQ_URL = os.getenv("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/")

async def start_consuming():
    """Start consuming messages from RabbitMQ"""
    try:
        connection = pika.BlockingConnection(pika.URLParameters(RABBITMQ_URL))
        channel = connection.channel()
        
        # Declare queues
        channel.queue_declare(queue='booking_notifications', durable=True)
        channel.queue_declare(queue='payment_notifications', durable=True)
        
        # Set up consumers
        channel.basic_consume(
            queue='booking_notifications',
            on_message_callback=handle_booking_notification,
            auto_ack=True
        )
        
        channel.basic_consume(
            queue='payment_notifications',
            on_message_callback=handle_payment_notification,
            auto_ack=True
        )
        
        print("Notification service started consuming messages...")
        channel.start_consuming()
        
    except Exception as e:
        print(f"Error starting consumer: {e}")

def handle_booking_notification(ch, method, properties, body):
    """Handle booking notification messages"""
    try:
        message = json.loads(body)
        print(f"Received booking notification: {message}")
        
        # Send email notification
        # send_email(
        #     to=message.get('user_email'),
        #     subject='Booking Confirmation',
        #     body=f"Your booking #{message.get('booking_id')} has been confirmed."
        # )
        
    except Exception as e:
        print(f"Error handling booking notification: {e}")

def handle_payment_notification(ch, method, properties, body):
    """Handle payment notification messages"""
    try:
        message = json.loads(body)
        print(f"Received payment notification: {message}")
        
        # Send email notification
        # send_email(
        #     to=message.get('user_email'),
        #     subject='Payment Confirmation',
        #     body=f"Your payment of ${message.get('amount')} has been processed."
        # )
        
    except Exception as e:
        print(f"Error handling payment notification: {e}")

