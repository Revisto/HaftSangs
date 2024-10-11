from django.db import models

class Game(models.Model):
    player1_id = models.CharField(max_length=255)
    player2_id = models.CharField(max_length=255)
    player1_score = models.IntegerField(default=0)
    player2_score = models.IntegerField(default=0)
    is_active = models.BooleanField(default=True)
    channel_name = models.CharField(max_length=255, null=True, blank=True)

    def __str__(self):
        return f"Game {self.id} - {self.player1_id} vs {self.player2_id if self.player2_id else 'Waiting'}"