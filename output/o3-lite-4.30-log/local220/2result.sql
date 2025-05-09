WITH
-- every appearance that ended in a WIN for the player’s team (match id kept to avoid double‑counting)
win_players AS (
    SELECT "match_api_id" AS mid, "home_player_1"  AS pid FROM "Match" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "match_api_id", "home_player_2"  FROM "Match" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "match_api_id", "home_player_3"  FROM "Match" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "match_api_id", "home_player_4"  FROM "Match" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "match_api_id", "home_player_5"  FROM "Match" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "match_api_id", "home_player_6"  FROM "Match" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "match_api_id", "home_player_7"  FROM "Match" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "match_api_id", "home_player_8"  FROM "Match" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "match_api_id", "home_player_9"  FROM "Match" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "match_api_id", "home_player_10" FROM "Match" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL SELECT "match_api_id", "home_player_11" FROM "Match" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL
    SELECT "match_api_id", "away_player_1"  FROM "Match" WHERE "away_team_goal" > "home_team_goal"
    UNION ALL SELECT "match_api_id", "away_player_2"  FROM "Match" WHERE "away_team_goal" > "home_team_goal"
    UNION ALL SELECT "match_api_id", "away_player_3"  FROM "Match" WHERE "away_team_goal" > "home_team_goal"
    UNION ALL SELECT "match_api_id", "away_player_4"  FROM "Match" WHERE "away_team_goal" > "home_team_goal"
    UNION ALL SELECT "match_api_id", "away_player_5"  FROM "Match" WHERE "away_team_goal" > "home_team_goal"
    UNION ALL SELECT "match_api_id", "away_player_6"  FROM "Match" WHERE "away_team_goal" > "home_team_goal"
    UNION ALL SELECT "match_api_id", "away_player_7"  FROM "Match" WHERE "away_team_goal" > "home_team_goal"
    UNION ALL SELECT "match_api_id", "away_player_8"  FROM "Match" WHERE "away_team_goal" > "home_team_goal"
    UNION ALL SELECT "match_api_id", "away_player_9"  FROM "Match" WHERE "away_team_goal" > "home_team_goal"
    UNION ALL SELECT "match_api_id", "away_player_10" FROM "Match" WHERE "away_team_goal" > "home_team_goal"
    UNION ALL SELECT "match_api_id", "away_player_11" FROM "Match" WHERE "away_team_goal" > "home_team_goal"
),
-- every appearance that ended in a LOSS for the player’s team
loss_players AS (
    SELECT "match_api_id" AS mid, "home_player_1"  AS pid FROM "Match" WHERE "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "match_api_id", "home_player_2"  FROM "Match" WHERE "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "match_api_id", "home_player_3"  FROM "Match" WHERE "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "match_api_id", "home_player_4"  FROM "Match" WHERE "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "match_api_id", "home_player_5"  FROM "Match" WHERE "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "match_api_id", "home_player_6"  FROM "Match" WHERE "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "match_api_id", "home_player_7"  FROM "Match" WHERE "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "match_api_id", "home_player_8"  FROM "Match" WHERE "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "match_api_id", "home_player_9"  FROM "Match" WHERE "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "match_api_id", "home_player_10" FROM "Match" WHERE "home_team_goal" < "away_team_goal"
    UNION ALL SELECT "match_api_id", "home_player_11" FROM "Match" WHERE "home_team_goal" < "away_team_goal"
    UNION ALL
    SELECT "match_api_id", "away_player_1"  FROM "Match" WHERE "away_team_goal" < "home_team_goal"
    UNION ALL SELECT "match_api_id", "away_player_2"  FROM "Match" WHERE "away_team_goal" < "home_team_goal"
    UNION ALL SELECT "match_api_id", "away_player_3"  FROM "Match" WHERE "away_team_goal" < "home_team_goal"
    UNION ALL SELECT "match_api_id", "away_player_4"  FROM "Match" WHERE "away_team_goal" < "home_team_goal"
    UNION ALL SELECT "match_api_id", "away_player_5"  FROM "Match" WHERE "away_team_goal" < "home_team_goal"
    UNION ALL SELECT "match_api_id", "away_player_6"  FROM "Match" WHERE "away_team_goal" < "home_team_goal"
    UNION ALL SELECT "match_api_id", "away_player_7"  FROM "Match" WHERE "away_team_goal" < "home_team_goal"
    UNION ALL SELECT "match_api_id", "away_player_8"  FROM "Match" WHERE "away_team_goal" < "home_team_goal"
    UNION ALL SELECT "match_api_id", "away_player_9"  FROM "Match" WHERE "away_team_goal" < "home_team_goal"
    UNION ALL SELECT "match_api_id", "away_player_10" FROM "Match" WHERE "away_team_goal" < "home_team_goal"
    UNION ALL SELECT "match_api_id", "away_player_11" FROM "Match" WHERE "away_team_goal" < "home_team_goal"
),
top_winner AS (
    SELECT p."player_name",
           'win'            AS match_outcome,
           COUNT(DISTINCT w.mid) AS total_matches
    FROM   win_players w
    JOIN   "Player" p ON p."player_api_id" = w.pid
    WHERE  w.pid IS NOT NULL
    GROUP  BY w.pid
    ORDER  BY total_matches DESC, p."player_name"
    LIMIT 1
),
top_loser AS (
    SELECT p."player_name",
           'loss'           AS match_outcome,
           COUNT(DISTINCT l.mid) AS total_matches
    FROM   loss_players l
    JOIN   "Player" p ON p."player_api_id" = l.pid
    WHERE  l.pid IS NOT NULL
    GROUP  BY l.pid
    ORDER  BY total_matches DESC, p."player_name"
    LIMIT 1
)
SELECT player_name, match_outcome, total_matches FROM top_winner
UNION ALL
SELECT player_name, match_outcome, total_matches FROM top_loser;