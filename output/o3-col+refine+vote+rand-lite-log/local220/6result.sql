WITH
------------------------------------------------------------------
-- every player-id that appeared for the WINNING side
winner AS (
         SELECT home_player_1  AS pid FROM Match WHERE home_team_goal > away_team_goal AND home_player_1  IS NOT NULL
 UNION ALL SELECT home_player_2  FROM Match WHERE home_team_goal > away_team_goal AND home_player_2  IS NOT NULL
 UNION ALL SELECT home_player_3  FROM Match WHERE home_team_goal > away_team_goal AND home_player_3  IS NOT NULL
 UNION ALL SELECT home_player_4  FROM Match WHERE home_team_goal > away_team_goal AND home_player_4  IS NOT NULL
 UNION ALL SELECT home_player_5  FROM Match WHERE home_team_goal > away_team_goal AND home_player_5  IS NOT NULL
 UNION ALL SELECT home_player_6  FROM Match WHERE home_team_goal > away_team_goal AND home_player_6  IS NOT NULL
 UNION ALL SELECT home_player_7  FROM Match WHERE home_team_goal > away_team_goal AND home_player_7  IS NOT NULL
 UNION ALL SELECT home_player_8  FROM Match WHERE home_team_goal > away_team_goal AND home_player_8  IS NOT NULL
 UNION ALL SELECT home_player_9  FROM Match WHERE home_team_goal > away_team_goal AND home_player_9  IS NOT NULL
 UNION ALL SELECT home_player_10 FROM Match WHERE home_team_goal > away_team_goal AND home_player_10 IS NOT NULL
 UNION ALL SELECT home_player_11 FROM Match WHERE home_team_goal > away_team_goal AND home_player_11 IS NOT NULL
 UNION ALL SELECT away_player_1  FROM Match WHERE away_team_goal > home_team_goal AND away_player_1  IS NOT NULL
 UNION ALL SELECT away_player_2  FROM Match WHERE away_team_goal > home_team_goal AND away_player_2  IS NOT NULL
 UNION ALL SELECT away_player_3  FROM Match WHERE away_team_goal > home_team_goal AND away_player_3  IS NOT NULL
 UNION ALL SELECT away_player_4  FROM Match WHERE away_team_goal > home_team_goal AND away_player_4  IS NOT NULL
 UNION ALL SELECT away_player_5  FROM Match WHERE away_team_goal > home_team_goal AND away_player_5  IS NOT NULL
 UNION ALL SELECT away_player_6  FROM Match WHERE away_team_goal > home_team_goal AND away_player_6  IS NOT NULL
 UNION ALL SELECT away_player_7  FROM Match WHERE away_team_goal > home_team_goal AND away_player_7  IS NOT NULL
 UNION ALL SELECT away_player_8  FROM Match WHERE away_team_goal > home_team_goal AND away_player_8  IS NOT NULL
 UNION ALL SELECT away_player_9  FROM Match WHERE away_team_goal > home_team_goal AND away_player_9  IS NOT NULL
 UNION ALL SELECT away_player_10 FROM Match WHERE away_team_goal > home_team_goal AND away_player_10 IS NOT NULL
 UNION ALL SELECT away_player_11 FROM Match WHERE away_team_goal > home_team_goal AND away_player_11 IS NOT NULL
),
------------------------------------------------------------------
-- every player-id that appeared for the LOSING side
loser AS (
         SELECT home_player_1  AS pid FROM Match WHERE home_team_goal < away_team_goal AND home_player_1  IS NOT NULL
 UNION ALL SELECT home_player_2  FROM Match WHERE home_team_goal < away_team_goal AND home_player_2  IS NOT NULL
 UNION ALL SELECT home_player_3  FROM Match WHERE home_team_goal < away_team_goal AND home_player_3  IS NOT NULL
 UNION ALL SELECT home_player_4  FROM Match WHERE home_team_goal < away_team_goal AND home_player_4  IS NOT NULL
 UNION ALL SELECT home_player_5  FROM Match WHERE home_team_goal < away_team_goal AND home_player_5  IS NOT NULL
 UNION ALL SELECT home_player_6  FROM Match WHERE home_team_goal < away_team_goal AND home_player_6  IS NOT NULL
 UNION ALL SELECT home_player_7  FROM Match WHERE home_team_goal < away_team_goal AND home_player_7  IS NOT NULL
 UNION ALL SELECT home_player_8  FROM Match WHERE home_team_goal < away_team_goal AND home_player_8  IS NOT NULL
 UNION ALL SELECT home_player_9  FROM Match WHERE home_team_goal < away_team_goal AND home_player_9  IS NOT NULL
 UNION ALL SELECT home_player_10 FROM Match WHERE home_team_goal < away_team_goal AND home_player_10 IS NOT NULL
 UNION ALL SELECT home_player_11 FROM Match WHERE home_team_goal < away_team_goal AND home_player_11 IS NOT NULL
 UNION ALL SELECT away_player_1  FROM Match WHERE away_team_goal < home_team_goal AND away_player_1  IS NOT NULL
 UNION ALL SELECT away_player_2  FROM Match WHERE away_team_goal < home_team_goal AND away_player_2  IS NOT NULL
 UNION ALL SELECT away_player_3  FROM Match WHERE away_team_goal < home_team_goal AND away_player_3  IS NOT NULL
 UNION ALL SELECT away_player_4  FROM Match WHERE away_team_goal < home_team_goal AND away_player_4  IS NOT NULL
 UNION ALL SELECT away_player_5  FROM Match WHERE away_team_goal < home_team_goal AND away_player_5  IS NOT NULL
 UNION ALL SELECT away_player_6  FROM Match WHERE away_team_goal < home_team_goal AND away_player_6  IS NOT NULL
 UNION ALL SELECT away_player_7  FROM Match WHERE away_team_goal < home_team_goal AND away_player_7  IS NOT NULL
 UNION ALL SELECT away_player_8  FROM Match WHERE away_team_goal < home_team_goal AND away_player_8  IS NOT NULL
 UNION ALL SELECT away_player_9  FROM Match WHERE away_team_goal < home_team_goal AND away_player_9  IS NOT NULL
 UNION ALL SELECT away_player_10 FROM Match WHERE away_team_goal < home_team_goal AND away_player_10 IS NOT NULL
 UNION ALL SELECT away_player_11 FROM Match WHERE away_team_goal < home_team_goal AND away_player_11 IS NOT NULL
),
------------------------------------------------------------------
-- count of wins per player
win_count AS (
    SELECT pid, COUNT(*) AS cnt
    FROM   winner
    GROUP  BY pid
),
------------------------------------------------------------------
-- count of losses per player
loss_count AS (
    SELECT pid, COUNT(*) AS cnt
    FROM   loser
    GROUP  BY pid
),
------------------------------------------------------------------
-- the single player with the most WINS
max_win AS (
    SELECT pid, cnt
    FROM   win_count
    ORDER  BY cnt DESC
    LIMIT 1
),
------------------------------------------------------------------
-- the single player with the most LOSSES
max_loss AS (
    SELECT pid, cnt
    FROM   loss_count
    ORDER  BY cnt DESC
    LIMIT 1
)
------------------------------------------------------------------
-- final answer
SELECT 'Most Winning Matches' AS category,
       p.player_name,
       mw.cnt          AS matches
FROM   max_win mw
JOIN   Player  p ON p.player_api_id = mw.pid

UNION ALL

SELECT 'Most Losing Matches',
       p.player_name,
       ml.cnt
FROM   max_loss ml
JOIN   Player   p ON p.player_api_id = ml.pid;