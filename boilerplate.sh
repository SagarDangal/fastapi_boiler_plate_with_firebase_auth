#!/bin/bash

# Boilerplate setup for FastAPI with Firebase and MongoDB

echo "Creating FastAPI with Firebase and MongoDB boilerplate..."

# Create project directory
PROJECT_DIR="fastapi_firebase_mongo"
mkdir -p $PROJECT_DIR/app
cd $PROJECT_DIR

# Create a virtual environment
echo "Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install required packages
echo "Installing required packages..."
pip install fastapi uvicorn pymongo pyrebase4 python-multipart pydantic firebase-admin python-dotenv

# Create the directory structure
echo "Setting up project structure..."
mkdir app

# Create .env file
echo "Creating .env file..."
cat <<EOT >> .env
MONGO_URI=mongodb://localhost:27017
DB_NAME=mydatabase
EOT

# Create app/main.py
echo "Creating app/main.py..."
cat <<EOT >> app/main.py
from fastapi import FastAPI, Depends, HTTPException
from pymongo.collection import Collection
from app.database import db
from app.models import UserCreate, Item
from app.auth import verify_firebase_token

app = FastAPI()

# MongoDB collections
users_collection: Collection = db["users"]
items_collection: Collection = db["items"]

# Route to create a new user (in MongoDB)
@app.post("/users/")
async def create_user(user: UserCreate, decoded_token: dict = Depends(verify_firebase_token)):
    # Check if user already exists
    if users_collection.find_one({"email": user.email}):
        raise HTTPException(status_code=400, detail="User already exists")
    
    # Insert new user into MongoDB
    user_data = {
        "email": user.email,
        "name": user.name,
    }
    result = users_collection.insert_one(user_data)
    return {"id": str(result.inserted_id), "email": user.email, "name": user.name}

# Route to fetch all users
@app.get("/users/")
async def get_users(decoded_token: dict = Depends(verify_firebase_token)):
    users = list(users_collection.find({}, {"_id": 1, "email": 1, "name": 1}))
    return users

# Route to create a new item
@app.post("/items/")
async def create_item(item: Item, decoded_token: dict = Depends(verify_firebase_token)):
    item_data = {
        "name": item.name,
        "description": item.description,
        "owner_id": decoded_token['uid']
    }
    result = items_collection.insert_one(item_data)
    return {"id": str(result.inserted_id), "name": item.name}

# Route to fetch all items
@app.get("/items/")
async def get_items(decoded_token: dict = Depends(verify_firebase_token)):
    items = list(items_collection.find({"owner_id": decoded_token['uid']}, {"_id": 1, "name": 1, "description": 1}))
    return items
EOT

# Create app/auth.py
echo "Creating app/auth.py..."
cat <<EOT >> app/auth.py
import firebase_admin
from firebase_admin import credentials, auth
from fastapi import HTTPException, Depends, Header

# Initialize Firebase Admin SDK
cred = credentials.Certificate("firebase-adminsdk.json")
firebase_admin.initialize_app(cred)

# Function to verify Firebase ID Token
def verify_firebase_token(authorization: str = Header(...)):
    try:
        if not authorization.startswith("Bearer "):
            raise HTTPException(status_code=403, detail="Invalid authorization format.")
        token = authorization.split("Bearer ")[1]
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except Exception as e:
        raise HTTPException(status_code=403, detail=f"Could not validate credentials: {str(e)}")
EOT

# Create app/database.py
echo "Creating app/database.py..."
cat <<EOT >> app/database.py
from pymongo import MongoClient
import os
from dotenv import load_dotenv

load_dotenv()

MONGO_URI = os.getenv("MONGO_URI")
DB_NAME = os.getenv("DB_NAME")

client = MongoClient(MONGO_URI)
db = client[DB_NAME]
EOT

# Create app/models.py
echo "Creating app/models.py..."
cat <<EOT >> app/models.py
from pydantic import BaseModel
from typing import Optional

class UserCreate(BaseModel):
    email: str
    name: str
    password: str

class UserResponse(BaseModel):
    id: str
    email: str
    name: str

class Item(BaseModel):
    name: str
    description: Optional[str] = None
EOT

# Create requirements.txt
echo "Creating requirements.txt..."
pip freeze > requirements.txt

echo "Boilerplate setup completed! Don't forget to add your Firebase credentials in 'firebase-adminsdk.json'."
