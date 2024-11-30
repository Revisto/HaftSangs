# 📡 Backend Directory Overview 🚀
### Welcome to the Backend! This is the powerhouse where all the WebSocket magic happens, enabling real-time communication for your "Haft Sang" game! 🎮✨

![Backend](https://cdn.dribbble.com/users/708424/screenshots/6809076/dribbble_4x.png?resize=1000x600&vertical=center)

### 🗂️ Directory Structure


client.py & client2.py:** 🛠️ Client testing scripts.
- **db.sqlite3:** 📦 Local database file.
- **Dockerfile:** 🚢 Docker configuration for building the backend.
- **game/:** 🗃️ Contains main game logic.
  - **admin.py, apps.py, models.py, views.py:** 🎯 Django app configurations and model structures.
  - **consumers.py:** 📢 WebSocket consumers connecting clients.
  - **routing.py:** 🛤️ WebSocket routing configuration.
- **game_server/:** 🌐 Server setup for ASGI compatibility.
  - **asgi.py, settings.py, urls.py, wsgi.py:** ⚙️ Django’s ASGI and WSGI configurations.
- **manage.py:** 🎛️ Django's command-line utility.
- **requirements.txt:** 📄 Python dependencies list.

## 🚦 How to Run
1. **Spin up Redis:**
   ```sh
   docker run -d --name backend-redis -p 6379:6379 redis
   ```

2. **Build and run the backend:**
   ```sh
   docker build -t backend .
   docker run --network="host" backend
   ```

## ⚙️ WebSocket Setup Details
- **GameConsumer:** 🤹 Manages player connections, match-making, and in-game messaging.
- **Redis:** 🔄 Used for storing player states and channels.

## 🔧 **Environment Variables:**
- `REDIS_HOST`: Redis server hostname (default: `localhost`)
- `REDIS_PORT`: Redis server port (default: `6379`)

## 📜 **Key Components:**
- **WebSocket Handling:** Manages WebSocket connections, message handling, and player matchmaking.
- **Redis Integration:** Utilizes Redis for managing player states and matchmaking queues.

Enjoy seamless, real-time gameplay with our robust backend! 🕹️🎉