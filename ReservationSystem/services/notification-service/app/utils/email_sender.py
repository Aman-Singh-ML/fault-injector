import aiosmtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os

SMTP_HOST = os.getenv("SMTP_HOST", "smtp.gmail.com")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_USER = os.getenv("SMTP_USER", "")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "")
FROM_EMAIL = os.getenv("FROM_EMAIL", "noreply@hotel.com")

async def send_email(to: str, subject: str, body: str, html: bool = False):
    """Send email notification"""
    try:
        message = MIMEMultipart("alternative")
        message["Subject"] = subject
        message["From"] = FROM_EMAIL
        message["To"] = to
        
        if html:
            part = MIMEText(body, "html")
        else:
            part = MIMEText(body, "plain")
        
        message.attach(part)
        
        # Send email
        await aiosmtplib.send(
            message,
            hostname=SMTP_HOST,
            port=SMTP_PORT,
            username=SMTP_USER,
            password=SMTP_PASSWORD,
            start_tls=True
        )
        
        print(f"Email sent to {to}")
        return True
        
    except Exception as e:
        print(f"Error sending email: {e}")
        return False

async def send_booking_confirmation(to: str, booking_data: dict):
    """Send booking confirmation email"""
    subject = f"Booking Confirmation - #{booking_data.get('booking_id')}"
    body = f"""
    Dear {booking_data.get('customer_name')},
    
    Your booking has been confirmed!
    
    Booking Details:
    - Booking ID: {booking_data.get('booking_id')}
    - Hotel: {booking_data.get('hotel_name')}
    - Check-in: {booking_data.get('check_in')}
    - Check-out: {booking_data.get('check_out')}
    - Total Amount: ${booking_data.get('total_amount')}
    
    Thank you for choosing our service!
    
    Best regards,
    Hotel Reservation Team
    """
    
    await send_email(to, subject, body)

async def send_payment_confirmation(to: str, payment_data: dict):
    """Send payment confirmation email"""
    subject = f"Payment Confirmation - {payment_data.get('transaction_id')}"
    body = f"""
    Dear Customer,
    
    Your payment has been processed successfully!
    
    Payment Details:
    - Transaction ID: {payment_data.get('transaction_id')}
    - Amount: ${payment_data.get('amount')}
    - Payment Method: {payment_data.get('payment_method')}
    
    Thank you!
    
    Best regards,
    Hotel Reservation Team
    """
    
    await send_email(to, subject, body)

