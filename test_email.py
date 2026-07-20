import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'backend'))
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'backend'))

from dotenv import load_dotenv
load_dotenv('.env')

from app.utils.otp import generate_otp, send_otp_email

otp = generate_otp()
print("OTP:", otp)
ok, msg = send_otp_email("greddy213041974@gmail.com", otp, "Ganesh")
print("OK:", ok)
print("MSG:", msg)
