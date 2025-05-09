WITH
-- 1. every appearance that ended in a WIN for that player’s side
win_app AS (
    SELECT "home_player_1"  AS pid FROM "Match" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "home_player_2"  FROM "Match" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "home_player_3"  FROM "Match" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "home_player_4"  FROM "Match" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "home_player_5"  FROM "Match" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "home_player_6"  FROM "Match" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "home_player_7"  FROM "Match" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "home_player_8"  FROM "Match" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "home_player_9"  FROM "Match" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "home_player_10" FROM "Match" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "home_player_11" FROM "Match" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "away_player_1"  FROM "Match" WHERE "away_team_goal" > "home_team_goal"
    UNION ALL SELECT "away_player_2"  FROM "Match" WHERE "away_team_goal" > "home_team_goal"
    UNION ALL SELECT "away_player_3"  FROM "Match" WHERE "away_team_goal" > "home_team_goal"
    UNION ALL SELECT "away_player_4"  FROM "Match" WHERE "away_team_goal" > "home_team_goal"
    UNION ALL SELECT "away_player_5"  FROM "Match" WHERE "away_team_goal" > "home_team_goal"
    UNION ALL SELECT "away_player_6"  FROM "Match" WHERE "away_team_goal" > "home_team_goal"
    UNION ALL SELECT "away_player_7"  FROM "Match" WHERE "away_team_goal" > "home_team_goal"
    UNION ALL SELECT "away_player_8"  FROM "Match" WHERE "away_team_goal" > "home_team_goal"
    UNION ALL SELECT "away_player_9"  FROM "Match" WHERE "away_team_goal" > "home_team_goal"
    UNION ALL SELECT "away_player_10" FROM "Match" WHERE "away_team_goal" > "home_team_goal"
    UNION ALL SELECT "away_player_11" FROM "Match" WHERE "away_team_goal" > "home_team_goal"
),
win_counts AS (
    SELECT pid AS player_api_id,
           COUNT(*) AS matches
    FROM   win_app
    WHERE  pid IS NOT NULL
    GROUP BY pid
),
best_win AS (
    SELECT player_api_id, matches AS match_count
    FROM   win_counts
    ORDER BY matches DESC
    LIMIT 1
),

-- 2. every appearance that ended in a LOSS for that player’s side
loss_app AS (
    SELECT "home_player_1"  AS pid FROM "Match" WHERE "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "home_player_2"  FROM "Match" WHERE "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "home_player_3"  FROM "Match" WHERE "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "home_player_4"  FROM "Match" WHERE "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "home_player_5"  FROM "Match" WHERE "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "home_player_6"  FROM "Match" WHERE "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "home_player_7"  FROM "Match" WHERE "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "home_player_8"  FROM "Match" WHERE "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "home_player_9"  FROM "Match" WHERE "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "home_player_10" FROM "Match" WHERE "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "home_player_11" FROM "Match" WHERE "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "away_player_1"  FROM "Match" WHERE "away_team_goal" < "home_team_goal"
    UNION ALL SELECT "away_player_2"  FROM "Match" WHERE "away_team_goal" < "home_team_goal"
    UNION ALL SELECT "away_player_3"  FROM "Match" WHERE "away_team_goal" < "home_team_goal"
    UNION ALL SELECT "away_player_4"  FROM "Match" WHERE "away_team_goal" < "home_team_goal"
    UNION ALL SELECT "away_player_5"  FROM "Match" WHERE "away_team_goal" < "home_team_goal"
    UNION ALL SELECT "away_player_6"  FROM "Match" WHERE "away_team_goal" < "home_team_goal"
    UNION ALL SELECT "away_player_7"  FROM "Match" WHERE "away_team_goal" < "home_team_goal"
    UNION ALL SELECT "away_player_8"  FROM "Match" WHERE "away_team_goal" < "home_team_goal"
    UNION ALL SELECT "away_player_9"  FROM "Match" WHERE "away_team_goal" < "home_team_goal"
    UNION ALL SELECT "away_player_10" FROM "Match" WHERE "away_team_goal" < "home_team_goal"
    UNION ALL SELECT "away_player_11" FROM "Match" WHERE "away_team_goal" < "home_team_goal"
),
loss_counts AS (
    SELECT pid AS player_api_id,
           COUNT(*) AS matches
    FROM   loss_app
    WHERE  pid IS NOT NULL
    GROUP BY pid
),
best_loss AS (
    SELECT player_api_id, matches AS match_count
    FROM   loss_counts
    ORDER BY matches DESC
    LIMIT 1
)

-- 3. return the two requested players
SELECT 'Most Wins'  AS category,
       p."player_name",
       bw."match_count"
FROM   best_win bw
JOIN   "Player" p ON p."player_api_id" = bw."player_api_id"

UNION ALL

SELECT 'Most Losses',
       p."player_name",
       bl."match_count"
FROM   best_loss bl
JOIN   "Player" p ON p."player_api_id" = bl."player_api_id";