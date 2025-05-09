WITH winner_players AS (           -- every (non–null) player that was on the winning side
    SELECT "home_player_1" AS player_id FROM Match WHERE "home_player_1" IS NOT NULL AND "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "home_player_2" FROM Match WHERE "home_player_2" IS NOT NULL AND "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "home_player_3" FROM Match WHERE "home_player_3" IS NOT NULL AND "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "home_player_4" FROM Match WHERE "home_player_4" IS NOT NULL AND "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "home_player_5" FROM Match WHERE "home_player_5" IS NOT NULL AND "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "home_player_6" FROM Match WHERE "home_player_6" IS NOT NULL AND "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "home_player_7" FROM Match WHERE "home_player_7" IS NOT NULL AND "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "home_player_8" FROM Match WHERE "home_player_8" IS NOT NULL AND "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "home_player_9" FROM Match WHERE "home_player_9" IS NOT NULL AND "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "home_player_10" FROM Match WHERE "home_player_10" IS NOT NULL AND "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "home_player_11" FROM Match WHERE "home_player_11" IS NOT NULL AND "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "away_player_1" FROM Match WHERE "away_player_1" IS NOT NULL AND "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "away_player_2" FROM Match WHERE "away_player_2" IS NOT NULL AND "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "away_player_3" FROM Match WHERE "away_player_3" IS NOT NULL AND "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "away_player_4" FROM Match WHERE "away_player_4" IS NOT NULL AND "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "away_player_5" FROM Match WHERE "away_player_5" IS NOT NULL AND "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "away_player_6" FROM Match WHERE "away_player_6" IS NOT NULL AND "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "away_player_7" FROM Match WHERE "away_player_7" IS NOT NULL AND "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "away_player_8" FROM Match WHERE "away_player_8" IS NOT NULL AND "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "away_player_9" FROM Match WHERE "away_player_9" IS NOT NULL AND "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "away_player_10" FROM Match WHERE "away_player_10" IS NOT NULL AND "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "away_player_11" FROM Match WHERE "away_player_11" IS NOT NULL AND "home_team_goal" < "away_team_goal"
),
loser_players AS (                -- every (non–null) player that was on the losing side
    SELECT "home_player_1" AS player_id FROM Match WHERE "home_player_1" IS NOT NULL AND "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "home_player_2" FROM Match WHERE "home_player_2" IS NOT NULL AND "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "home_player_3" FROM Match WHERE "home_player_3" IS NOT NULL AND "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "home_player_4" FROM Match WHERE "home_player_4" IS NOT NULL AND "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "home_player_5" FROM Match WHERE "home_player_5" IS NOT NULL AND "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "home_player_6" FROM Match WHERE "home_player_6" IS NOT NULL AND "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "home_player_7" FROM Match WHERE "home_player_7" IS NOT NULL AND "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "home_player_8" FROM Match WHERE "home_player_8" IS NOT NULL AND "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "home_player_9" FROM Match WHERE "home_player_9" IS NOT NULL AND "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "home_player_10" FROM Match WHERE "home_player_10" IS NOT NULL AND "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "home_player_11" FROM Match WHERE "home_player_11" IS NOT NULL AND "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "away_player_1" FROM Match WHERE "away_player_1" IS NOT NULL AND "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "away_player_2" FROM Match WHERE "away_player_2" IS NOT NULL AND "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "away_player_3" FROM Match WHERE "away_player_3" IS NOT NULL AND "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "away_player_4" FROM Match WHERE "away_player_4" IS NOT NULL AND "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "away_player_5" FROM Match WHERE "away_player_5" IS NOT NULL AND "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "away_player_6" FROM Match WHERE "away_player_6" IS NOT NULL AND "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "away_player_7" FROM Match WHERE "away_player_7" IS NOT NULL AND "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "away_player_8" FROM Match WHERE "away_player_8" IS NOT NULL AND "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "away_player_9" FROM Match WHERE "away_player_9" IS NOT NULL AND "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "away_player_10" FROM Match WHERE "away_player_10" IS NOT NULL AND "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "away_player_11" FROM Match WHERE "away_player_11" IS NOT NULL AND "home_team_goal" > "away_team_goal"
),
win_counts AS (                    -- number of wins per player
    SELECT player_id, COUNT(*) AS win_matches
    FROM winner_players
    GROUP BY player_id
),
loss_counts AS (                   -- number of losses per player
    SELECT player_id, COUNT(*) AS loss_matches
    FROM loser_players
    GROUP BY player_id
),
max_win AS (                       -- player with most wins
    SELECT player_id, win_matches
    FROM win_counts
    ORDER BY win_matches DESC
    LIMIT 1
),
max_loss AS (                      -- player with most losses
    SELECT player_id, loss_matches
    FROM loss_counts
    ORDER BY loss_matches DESC
    LIMIT 1
)
SELECT 'most_wins'  AS metric,
       p.player_name,
       mw.win_matches  AS match_count
FROM   max_win  mw
JOIN   Player   p ON p.player_api_id = mw.player_id

UNION ALL

SELECT 'most_losses',
       p.player_name,
       ml.loss_matches
FROM   max_loss ml
JOIN   Player   p ON p.player_api_id = ml.player_id;