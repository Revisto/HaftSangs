import asyncio
import websockets
import json

async def test_websocket():
    uri = "ws://127.0.0.1:8000/ws/game/"
    async with websockets.connect(uri) as websocket:
        # Receive a response
        response = await websocket.recv()
        print(f"< Received: {response}")

asyncio.get_event_loop().run_until_complete(test_websocket())
