# password_web Installation Guide

 'sudo apt update'
    2. git clone „Link zu Repo“
    3. cd password_web
    4. sudo apt install python3-flask -y
    5. sudo apt install python3-pip -y
    6. pip install zxcvbn
    7. python3 main.py
    
 for WSGI
 sudo apt update && sudo apt install build-essential python3-dev
 pip install uwsgi
 uwsgi --http :9000 --wsgi-file main.py --callable app
