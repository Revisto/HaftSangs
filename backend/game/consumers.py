import redis
import json
import logging
from .models import Game
from asgiref.sync import sync_to_async
from django.db.models import Q
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.exceptions import ChannelFull
import asyncio

logger = logging.getLogger(__name__)

redis_client = redis.StrictRedis(host='redis', port=6379, db=0)

# remove redis current db data
redis_client.flushdb()


class GameConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        logger.debug("WebSocket connection established")
        print("WebSocket connection established")
        self.room_group_name = 'game_room'
        print(f"Adding to group: {self.room_group_name}")
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )
        await self.accept()
        print("WebSocket connection accepted")

    async def disconnect(self, close_code):
        logger.debug("WebSocket connection closed")
        print(f"WebSocket connection closed with code: {close_code}")
        print(f"Discarding from group: {self.room_group_name}")
        waiting_players = await self.get_waiting_players()
        if self.channel_name in waiting_players:
            await self.remove_player_from_waiting_list(self.channel_name)
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )

    async def receive(self, text_data=None, bytes_data=None):
        if text_data:
            print(f"Received text data: {text_data}")
            await self.handle_text_data(text_data)
        elif bytes_data:
            print(f"Received binary data: {bytes_data}")
            await self.handle_binary_data(bytes_data)

    async def handle_text_data(self, text_data):
        logger.debug(f"WebSocket message received: {text_data}")
        print(f"WebSocket message received: {text_data}")
        try:
            data = json.loads(text_data)
            print(f"Decoded JSON data: {data}")
            await self.process_data(data)
        except json.JSONDecodeError as e:
            logger.error(f"Failed to decode JSON message: {e}")
            print(f"Failed to decode JSON message: {e}")

    async def handle_binary_data(self, bytes_data):
        logger.debug(f"WebSocket binary message received: {bytes_data}")
        print(f"WebSocket binary message received: {bytes_data}")
        try:
            text_data = bytes_data.decode('utf-8')
            print(f"Decoded binary data to text: {text_data}")
            data = json.loads(text_data)
            print(f"Decoded JSON data: {data}")
            await self.process_data(data)
        except (UnicodeDecodeError, json.JSONDecodeError) as e:
            logger.error(f"Failed to process binary message: {e}")
            print(f"Failed to process binary message: {e}")

    async def process_data(self, data):
        print(f"Processing data: {data}")
        obstacles_data = data.get('obstacles_data')
        slingshot_data = data.get('slingshot_data')
        request_match = data.get('request_match', False)
        sender_id = data.get('sender_id')
        
        await self.set_player_channel_name(sender_id, self.channel_name)
        
        if request_match:
            print(f"Requesting match for sender: {sender_id}")
            await self.find_match(sender_id)

        # check if user is in active game, if not no access
        game = await sync_to_async(Game.objects.filter(
            (Q(player1_id=sender_id) | Q(player2_id=sender_id)) & Q(is_active=True)
        ).first)()
        
        if not game:
            return
        
        opponent_id = game.player1_id if game.player2_id == sender_id else game.player2_id
        opponent_channel_name = await self.get_player_channel_name(opponent_id)

        if obstacles_data:
            print(f"Sending obstacles update: {obstacles_data}")
            await self.send_direct_message(opponent_channel_name, 'obstacles_data', obstacles_data) 
        if slingshot_data:
            print(f"Sending slingshot update: {slingshot_data}")
            await self.send_direct_message(opponent_channel_name, 'slingshot_data', slingshot_data)

    async def send_direct_message(self, channel_name, message_type, data):
        print(f"Sending direct message of type: {message_type} with data: {data} to channel: {channel_name}")
        try:
            await self.channel_layer.send(
                channel_name,
                {
                    'type': message_type,
                    'data': data,
                }
            )
        except ChannelFull:
            print(f"Channel {channel_name} is full, retrying...")
            await asyncio.sleep(1)  # Wait for 1 second before retrying
            await self.send_direct_message(channel_name, message_type, data)

    async def match_waiting(self, event):
        await self.send_event_data(event, 'match_waiting')
        
    async def match_found(self, event):
        await self.send_event_data(event, 'match_found')
    
    async def obstacles_data(self, event):
        await self.send_event_data(event, 'obstacles_data')
    
    async def slingshot_data(self, event):
        await self.send_event_data(event, 'slingshot_data')

    async def send_event_data(self, event, data_key):
        data = event['data']
        exclude_sender = event.get('exclude_sender')
        if self.channel_name != exclude_sender:
            await self.send(text_data=json.dumps({
                data_key: data
            }))
            print(f"Sent event data: {data_key}")

    @sync_to_async
    def get_waiting_players(self):
        waiting_players = redis_client.lrange('waiting_players', 0, -1)
        for i in range(len(waiting_players)):
            waiting_players[i] = waiting_players[i].decode('utf-8')
        print(f"Retrieved waiting players: {waiting_players}")
        return waiting_players

    @sync_to_async
    def get_waiting_players(self):
        waiting_players = redis_client.lrange('waiting_players', 0, -1)
        for i in range(len(waiting_players)):
            if isinstance(waiting_players[i], bytes):
                waiting_players[i] = waiting_players[i].decode('utf-8')
        print(f"Retrieved waiting players: {waiting_players}")
        return waiting_players

    @sync_to_async
    def add_player_to_waiting_list(self, player_id):
        redis_client.rpush('waiting_players', player_id)
        print(f"Added player to waiting list: {player_id}")

    @sync_to_async
    def remove_player_from_waiting_list(self, player_id):
        redis_client.lrem('waiting_players', 0, player_id)
        print(f"Removed player from waiting list: {player_id}")

    @sync_to_async
    def get_player_channel_name(self, player_id):
        channel_name = redis_client.hget('player_channels', player_id)
        if isinstance(channel_name, bytes):
            channel_name = channel_name.decode('utf-8')
        print(f"Retrieved channel name for player {player_id}: {channel_name}")
        return channel_name

    @sync_to_async
    def set_player_channel_name(self, player_id, channel_name):
        redis_client.hset('player_channels', player_id, channel_name)
        print(f"Set channel name for player {player_id}: {channel_name}")

    @sync_to_async
    def make_match(self, player1_id, player2_id):
        game = Game.objects.create(player1_id=player1_id, player2_id=player2_id)
        print(f"Created match between player {player1_id} and player {player2_id}: Game ID {game.id}")
        return game

    @sync_to_async
    def end_match(self, player1_id, player2_id):
        game = Game.objects.get(player1_id=player1_id, player2_id=player2_id)
        game.is_active = False
        game.save()

    async def find_match(self, sender_id):
        print(f"Finding match for sender: {sender_id}")
        waiting_players = await self.get_waiting_players()
        print(f"Ended a match")
        print(f"waiting players: {self.get_waiting_players()}")
        print(f"player channels: {redis_client.hgetall('player_channels')}")
        print(f"my channel {self.channel_name}")
        print(f"my channel {self.get_player_channel_name(sender_id)}")
        print(f"my id {sender_id}")

        if waiting_players and waiting_players[0] != sender_id:
            player1_id = waiting_players[0]
            player2_id = sender_id
            print(f"Match found: {player1_id} vs {player2_id}")
            await self.remove_player_from_waiting_list(player1_id)
            game = await self.make_match(player1_id, player2_id)
            player1_channel_name = await self.get_player_channel_name(player1_id)
            player2_channel_name = await self.get_player_channel_name(player2_id)

            await self.send_direct_message(player1_channel_name, 'match_found', {
                'game_id': game.id,
                'opponent_id': player2_id,
                'role': 'white',
            })
            
            await self.send_direct_message(player2_channel_name, 'match_found', {
                'game_id': game.id,
                'opponent_id': player1_id,
                'role': 'black',
            })
        else:
            print(f"No match found, adding sender {sender_id} to waiting list")
            await self.add_player_to_waiting_list(sender_id)
            await self.send_direct_message(self.channel_name, 'match_waiting', {})