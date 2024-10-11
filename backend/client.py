import asyncio
import websockets
import json

async def test_websocket():
    uri = "ws://127.0.0.1:8000/ws/game/"
    async with websockets.connect(uri) as websocket:
        # Send a test message
        test_message = json.dumps({
            'obstacles_data': {'obstacle1': 'data1', 'obstacle2': 'data2'}
        })
        await websocket.send(test_message)
        print(f"> Sent: {test_message}")


asyncio.get_event_loop().run_until_complete(test_websocket())
