@echo off
echo Creating FastAPI with Firebase and MongoDB boilerplate...

:: Create project directory
set PROJECT_DIR=fastapi_firebase_mongo
mkdir %PROJECT_DIR%\app
cd %PROJECT_DIR%

:: Create a virtual environment
echo Creating virtual environment...
python -m venv venv
call venv\Scripts\activate

:: Install required packages
echo Installing required packages...
pip install fastapi uvicorn pymongo pyrebase4 python-multipart pydantic firebase-admin python-dotenv

:: Create the directory structure
echo Setting up project structure...
mkdir app

:: Create .env file
echo Creating .env file...
echo MONGO_URI=mongodb://localhost:27017 > .env
echo DB_NAME=mydatabase >> .env

:: Create app\main.py
echo Creating app\main.py...
(
echo from fastapi import FastAPI, Depends, HTTPException
echo from pymongo.collection import Collection
echo from app.database import db
echo from app.models import UserCreate, Item
echo from app.auth import verify_firebase_token
echo.
echo app = FastAPI()
echo.
echo # MongoDB collections
echo users_collection: Collection = db["users"]
echo items_collection: Collection = db["items"]
echo.
echo # Route to create a new user (in MongoDB)
echo @app.post("/users/")
echo async def create_user(user: UserCreate, decoded_token: dict = Depends(verify_firebase_token)):
echo     # Check if user already exists
echo     if users_collection.find_one({"email": user.email}):
echo         raise HTTPException(status_code=400, detail="User already exists")
echo.
echo     # Insert new user into MongoDB
echo     user_data = {
echo         "email": user.email,
echo         "name": user.name,
echo     }
echo     result = users_collection.insert_one(user_data)
echo     return {"id": str(result.inserted_id), "email": user.email, "name": user.name}
echo.
echo # Route to fetch all users
echo @app.get("/users/")
echo async def get_users(decoded_token: dict = Depends(verify_firebase_token)):
echo     users = list(users_collection.find({}, {"_id": 1, "email": 1, "name": 1}))
echo     return users
echo.
echo # Route to create a new item
echo @app.post("/items/")
echo async def create_item(item: Item, decoded_token: dict = Depends(verify_firebase_token)):
echo     item_data = {
echo         "name": item.name,
echo         "description": item.description,
echo         "owner_id": decoded_token['uid']
echo     }
echo     result = items_collection.insert_one(item_data)
echo     return {"id": str(result.inserted_id), "name": item.name}
echo.
echo # Route to fetch all items
echo @app.get("/items/")
echo async def get_items(decoded_token: dict = Depends(verify_firebase_token)):
echo     items = list(items_collection.find({"owner_id": decoded_token['uid']}, {"_id": 1, "name": 1, "description": 1}))
echo     return items
) > app\main.py

:: Create app\auth.py
echo Creating app\auth.py...
(
echo import firebase_admin
echo from firebase_admin import credentials, auth
echo from fastapi import HTTPException, Depends, Header
echo.
echo # Initialize Firebase Admin SDK
echo cred = credentials.Certificate("firebase-adminsdk.json")
echo firebase_admin.initialize_app(cred)
echo.
echo # Function to verify Firebase ID Token
echo def verify_firebase_token(authorization: str = Header(...)):
echo     try:
echo         if not authorization.startswith("Bearer "):
echo             raise HTTPException(status_code=403, detail="Invalid authorization format.")
echo         token = authorization.split("Bearer ")[1]
echo         decoded_token = auth.verify_id_token(token)
echo         return decoded_token
echo     except Exception as e:
echo         raise HTTPException(status_code=403, detail=f"Could not validate credentials: {str(e)}")
) > app\auth.py

:: Create app\database.py
echo Creating app\database.py...
(
echo from pymongo import MongoClient
echo import os
echo from dotenv import load_dotenv
echo.
echo load_dotenv()
echo.
echo MONGO_URI = os.getenv("MONGO_URI")
echo DB_NAME = os.getenv("DB_NAME")
echo.
echo client = MongoClient(MONGO_URI)
echo db = client[DB_NAME]
) > app\database.py

:: Create app\models.py
echo Creating app\models.py...
(
echo from pydantic import BaseModel
echo from typing import Optional
echo.
echo class UserCreate(BaseModel):
echo     email: str
echo     name: str
echo     password: str
echo.
echo class UserResponse(BaseModel):
echo     id: str
echo     email: str
echo     name: str
echo.
echo class Item(BaseModel):
echo     name: str
echo     description: Optional[str] = None
) > app\models.py

:: Create requirements.txt
echo Creating requirements.txt...
pip freeze > requirements.txt

echo Boilerplate setup completed! Don't forget to add your Firebase credentials in 'firebase-adminsdk.json'.

