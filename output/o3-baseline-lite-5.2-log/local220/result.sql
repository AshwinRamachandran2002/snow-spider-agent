WITH player_outcomes AS (
    /* every appearance of every player together with the match outcome
       (win/loss from that player’s team point of view, draws discarded) */
    SELECT "home_player_1"  AS player_id,
           CASE WHEN "home_team_goal" > "away_team_goal" THEN 'win'
                WHEN "home_team_goal" < "away_team_goal" THEN 'loss' END AS outcome
    FROM   "Match"
    UNION ALL SELECT "home_player_2",  CASE WHEN home_team_goal > away_team_goal THEN 'win' WHEN home_team_goal < away_team_goal THEN 'loss' END FROM "Match"
    UNION ALL SELECT "home_player_3",  CASE WHEN home_team_goal > away_team_goal THEN 'win' WHEN home_team_goal < away_team_goal THEN 'loss' END FROM "Match"
    UNION ALL SELECT "home_player_4",  CASE WHEN home_team_goal > away_team_goal THEN 'win' WHEN home_team_goal < away_team_goal THEN 'loss' END FROM "Match"
    UNION ALL SELECT "home_player_5",  CASE WHEN home_team_goal > away_team_goal THEN 'win' WHEN home_team_goal < away_team_goal THEN 'loss' END FROM "Match"
    UNION ALL SELECT "home_player_6",  CASE WHEN home_team_goal > away_team_goal THEN 'win' WHEN home_team_goal < away_team_goal THEN 'loss' END FROM "Match"
    UNION ALL SELECT "home_player_7",  CASE WHEN home_team_goal > away_team_goal THEN 'win' WHEN home_team_goal < away_team_goal THEN 'loss' END FROM "Match"
    UNION ALL SELECT "home_player_8",  CASE WHEN home_team_goal > away_team_goal THEN 'win' WHEN home_team_goal < away_team_goal THEN 'loss' END FROM "Match"
    UNION ALL SELECT "home_player_9",  CASE WHEN home_team_goal > away_team_goal THEN 'win' WHEN home_team_goal < away_team_goal THEN 'loss' END FROM "Match"
    UNION ALL SELECT "home_player_10", CASE WHEN home_team_goal > away_team_goal THEN 'win' WHEN home_team_goal < away_team_goal THEN 'loss' END FROM "Match"
    UNION ALL SELECT "home_player_11", CASE WHEN home_team_goal > away_team_goal THEN 'win' WHEN home_team_goal < away_team_goal THEN 'loss' END FROM "Match"

    UNION ALL SELECT "away_player_1",  CASE WHEN away_team_goal > home_team_goal THEN 'win' WHEN away_team_goal < home_team_goal THEN 'loss' END FROM "Match"
    UNION ALL SELECT "away_player_2",  CASE WHEN away_team_goal > home_team_goal THEN 'win' WHEN away_team_goal < home_team_goal THEN 'loss' END FROM "Match"
    UNION ALL SELECT "away_player_3",  CASE WHEN away_team_goal > home_team_goal THEN 'win' WHEN away_team_goal < home_team_goal THEN 'loss' END FROM "Match"
    UNION ALL SELECT "away_player_4",  CASE WHEN away_team_goal > home_team_goal THEN 'win' WHEN away_team_goal < home_team_goal THEN 'loss' END FROM "Match"
    UNION ALL SELECT "away_player_5",  CASE WHEN away_team_goal > home_team_goal THEN 'win' WHEN away_team_goal < home_team_goal THEN 'loss' END FROM "Match"
    UNION ALL SELECT "away_player_6",  CASE WHEN away_team_goal > home_team_goal THEN 'win' WHEN away_team_goal < home_team_goal THEN 'loss' END FROM "Match"
    UNION ALL SELECT "away_player_7",  CASE WHEN away_team_goal > home_team_goal THEN 'win' WHEN away_team_goal < home_team_goal THEN 'loss' END FROM "Match"
    UNION ALL SELECT "away_player_8",  CASE WHEN away_team_goal > home_team_goal THEN 'win' WHEN away_team_goal < home_team_goal THEN 'loss' END FROM "Match"
    UNION ALL SELECT "away_player_9",  CASE WHEN away_team_goal > home_team_goal THEN 'win' WHEN away_team_goal < home_team_goal THEN 'loss' END FROM "Match"
    UNION ALL SELECT "away_player_10", CASE WHEN away_team_goal > home_team_goal THEN 'win' WHEN away_team_goal < home_team_goal THEN 'loss' END FROM "Match"
    UNION ALL SELECT "away_player_11", CASE WHEN away_team_goal > home_team_goal THEN 'win' WHEN away_team_goal < home_team_goal THEN 'loss' END FROM "Match"
),
player_counts AS (
    /* keep only appearances that are wins or losses, aggregate per player */
    SELECT   player_id,
             SUM(CASE WHEN outcome = 'win'  THEN 1 ELSE 0 END) AS wins,
             SUM(CASE WHEN outcome = 'loss' THEN 1 ELSE 0 END) AS losses
    FROM     player_outcomes
    WHERE    player_id IS NOT NULL
      AND    outcome    IS NOT NULL          -- removes draws
    GROUP BY player_id
),
limits AS (
    SELECT MAX(wins)  AS max_wins,
           MAX(losses) AS max_losses
    FROM   player_counts
)
SELECT 'most_wins'  AS category,
       pl.player_name,
       pc.wins  AS matches
FROM   player_counts pc
JOIN   limits       l  ON pc.wins  = l.max_wins
JOIN   Player       pl ON pl.player_api_id = pc.player_id

UNION ALL

SELECT 'most_losses',
       pl.player_name,
       pc.losses
FROM   player_counts pc
JOIN   limits       l  ON pc.losses = l.max_losses
JOIN   Player       pl ON pl.player_api_id = pc.player_id
ORDER BY category;