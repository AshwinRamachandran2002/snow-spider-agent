WITH
------------------------------------------------------------------
--  every appearance where the player’s team WON the match
------------------------------------------------------------------
winner_appearances AS (
    SELECT home_player_1 AS player_api_id FROM "Match"
     WHERE home_player_1 IS NOT NULL AND home_team_goal > away_team_goal
    UNION ALL SELECT home_player_2  FROM "Match" WHERE home_player_2  IS NOT NULL AND home_team_goal > away_team_goal
    UNION ALL SELECT home_player_3  FROM "Match" WHERE home_player_3  IS NOT NULL AND home_team_goal > away_team_goal
    UNION ALL SELECT home_player_4  FROM "Match" WHERE home_player_4  IS NOT NULL AND home_team_goal > away_team_goal
    UNION ALL SELECT home_player_5  FROM "Match" WHERE home_player_5  IS NOT NULL AND home_team_goal > away_team_goal
    UNION ALL SELECT home_player_6  FROM "Match" WHERE home_player_6  IS NOT NULL AND home_team_goal > away_team_goal
    UNION ALL SELECT home_player_7  FROM "Match" WHERE home_player_7  IS NOT NULL AND home_team_goal > away_team_goal
    UNION ALL SELECT home_player_8  FROM "Match" WHERE home_player_8  IS NOT NULL AND home_team_goal > away_team_goal
    UNION ALL SELECT home_player_9  FROM "Match" WHERE home_player_9  IS NOT NULL AND home_team_goal > away_team_goal
    UNION ALL SELECT home_player_10 FROM "Match" WHERE home_player_10 IS NOT NULL AND home_team_goal > away_team_goal
    UNION ALL SELECT home_player_11 FROM "Match" WHERE home_player_11 IS NOT NULL AND home_team_goal > away_team_goal
    
    UNION ALL SELECT away_player_1  FROM "Match" WHERE away_player_1  IS NOT NULL AND away_team_goal > home_team_goal
    UNION ALL SELECT away_player_2  FROM "Match" WHERE away_player_2  IS NOT NULL AND away_team_goal > home_team_goal
    UNION ALL SELECT away_player_3  FROM "Match" WHERE away_player_3  IS NOT NULL AND away_team_goal > home_team_goal
    UNION ALL SELECT away_player_4  FROM "Match" WHERE away_player_4  IS NOT NULL AND away_team_goal > home_team_goal
    UNION ALL SELECT away_player_5  FROM "Match" WHERE away_player_5  IS NOT NULL AND away_team_goal > home_team_goal
    UNION ALL SELECT away_player_6  FROM "Match" WHERE away_player_6  IS NOT NULL AND away_team_goal > home_team_goal
    UNION ALL SELECT away_player_7  FROM "Match" WHERE away_player_7  IS NOT NULL AND away_team_goal > home_team_goal
    UNION ALL SELECT away_player_8  FROM "Match" WHERE away_player_8  IS NOT NULL AND away_team_goal > home_team_goal
    UNION ALL SELECT away_player_9  FROM "Match" WHERE away_player_9  IS NOT NULL AND away_team_goal > home_team_goal
    UNION ALL SELECT away_player_10 FROM "Match" WHERE away_player_10 IS NOT NULL AND away_team_goal > home_team_goal
    UNION ALL SELECT away_player_11 FROM "Match" WHERE away_player_11 IS NOT NULL AND away_team_goal > home_team_goal
),
winner_counts AS (
    SELECT player_api_id, COUNT(*) AS matches
    FROM   winner_appearances
    GROUP  BY player_api_id
),
top_winner AS (
    SELECT player_api_id, matches
    FROM   winner_counts
    ORDER  BY matches DESC
    LIMIT  1
),

------------------------------------------------------------------
--  every appearance where the player’s team LOST the match
------------------------------------------------------------------
loser_appearances AS (
    SELECT home_player_1 AS player_api_id FROM "Match"
     WHERE home_player_1 IS NOT NULL AND home_team_goal < away_team_goal
    UNION ALL SELECT home_player_2  FROM "Match" WHERE home_player_2  IS NOT NULL AND home_team_goal < away_team_goal
    UNION ALL SELECT home_player_3  FROM "Match" WHERE home_player_3  IS NOT NULL AND home_team_goal < away_team_goal
    UNION ALL SELECT home_player_4  FROM "Match" WHERE home_player_4  IS NOT NULL AND home_team_goal < away_team_goal
    UNION ALL SELECT home_player_5  FROM "Match" WHERE home_player_5  IS NOT NULL AND home_team_goal < away_team_goal
    UNION ALL SELECT home_player_6  FROM "Match" WHERE home_player_6  IS NOT NULL AND home_team_goal < away_team_goal
    UNION ALL SELECT home_player_7  FROM "Match" WHERE home_player_7  IS NOT NULL AND home_team_goal < away_team_goal
    UNION ALL SELECT home_player_8  FROM "Match" WHERE home_player_8  IS NOT NULL AND home_team_goal < away_team_goal
    UNION ALL SELECT home_player_9  FROM "Match" WHERE home_player_9  IS NOT NULL AND home_team_goal < away_team_goal
    UNION ALL SELECT home_player_10 FROM "Match" WHERE home_player_10 IS NOT NULL AND home_team_goal < away_team_goal
    UNION ALL SELECT home_player_11 FROM "Match" WHERE home_player_11 IS NOT NULL AND home_team_goal < away_team_goal
    
    UNION ALL SELECT away_player_1  FROM "Match" WHERE away_player_1  IS NOT NULL AND away_team_goal < home_team_goal
    UNION ALL SELECT away_player_2  FROM "Match" WHERE away_player_2  IS NOT NULL AND away_team_goal < home_team_goal
    UNION ALL SELECT away_player_3  FROM "Match" WHERE away_player_3  IS NOT NULL AND away_team_goal < home_team_goal
    UNION ALL SELECT away_player_4  FROM "Match" WHERE away_player_4  IS NOT NULL AND away_team_goal < home_team_goal
    UNION ALL SELECT away_player_5  FROM "Match" WHERE away_player_5  IS NOT NULL AND away_team_goal < home_team_goal
    UNION ALL SELECT away_player_6  FROM "Match" WHERE away_player_6  IS NOT NULL AND away_team_goal < home_team_goal
    UNION ALL SELECT away_player_7  FROM "Match" WHERE away_player_7  IS NOT NULL AND away_team_goal < home_team_goal
    UNION ALL SELECT away_player_8  FROM "Match" WHERE away_player_8  IS NOT NULL AND away_team_goal < home_team_goal
    UNION ALL SELECT away_player_9  FROM "Match" WHERE away_player_9  IS NOT NULL AND away_team_goal < home_team_goal
    UNION ALL SELECT away_player_10 FROM "Match" WHERE away_player_10 IS NOT NULL AND away_team_goal < home_team_goal
    UNION ALL SELECT away_player_11 FROM "Match" WHERE away_player_11 IS NOT NULL AND away_team_goal < home_team_goal
),
loser_counts AS (
    SELECT player_api_id, COUNT(*) AS matches
    FROM   loser_appearances
    GROUP  BY player_api_id
),
top_loser AS (
    SELECT player_api_id, matches
    FROM   loser_counts
    ORDER  BY matches DESC
    LIMIT  1
)

------------------------------------------------------------------
--  final result: one row for most wins, one row for most losses
------------------------------------------------------------------
SELECT 'most_wins'  AS category,
       p.player_name,
       w.matches
FROM   top_winner w
JOIN   "Player"  p ON p.player_api_id = w.player_api_id

UNION ALL

SELECT 'most_losses',
       p.player_name,
       l.matches
FROM   top_loser  l
JOIN   "Player"  p ON p.player_api_id = l.player_api_id;