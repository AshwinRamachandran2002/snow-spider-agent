WITH winner_appearances AS (
      SELECT "home_player_1" AS player_id FROM "Match" WHERE home_team_goal > away_team_goal AND "home_player_1" IS NOT NULL
UNION ALL SELECT "home_player_2" FROM "Match" WHERE home_team_goal > away_team_goal AND "home_player_2" IS NOT NULL
UNION ALL SELECT "home_player_3" FROM "Match" WHERE home_team_goal > away_team_goal AND "home_player_3" IS NOT NULL
UNION ALL SELECT "home_player_4" FROM "Match" WHERE home_team_goal > away_team_goal AND "home_player_4" IS NOT NULL
UNION ALL SELECT "home_player_5" FROM "Match" WHERE home_team_goal > away_team_goal AND "home_player_5" IS NOT NULL
UNION ALL SELECT "home_player_6" FROM "Match" WHERE home_team_goal > away_team_goal AND "home_player_6" IS NOT NULL
UNION ALL SELECT "home_player_7" FROM "Match" WHERE home_team_goal > away_team_goal AND "home_player_7" IS NOT NULL
UNION ALL SELECT "home_player_8" FROM "Match" WHERE home_team_goal > away_team_goal AND "home_player_8" IS NOT NULL
UNION ALL SELECT "home_player_9" FROM "Match" WHERE home_team_goal > away_team_goal AND "home_player_9" IS NOT NULL
UNION ALL SELECT "home_player_10" FROM "Match" WHERE home_team_goal > away_team_goal AND "home_player_10" IS NOT NULL
UNION ALL SELECT "home_player_11" FROM "Match" WHERE home_team_goal > away_team_goal AND "home_player_11" IS NOT NULL
UNION ALL SELECT "away_player_1" FROM "Match" WHERE away_team_goal > home_team_goal AND "away_player_1" IS NOT NULL
UNION ALL SELECT "away_player_2" FROM "Match" WHERE away_team_goal > home_team_goal AND "away_player_2" IS NOT NULL
UNION ALL SELECT "away_player_3" FROM "Match" WHERE away_team_goal > home_team_goal AND "away_player_3" IS NOT NULL
UNION ALL SELECT "away_player_4" FROM "Match" WHERE away_team_goal > home_team_goal AND "away_player_4" IS NOT NULL
UNION ALL SELECT "away_player_5" FROM "Match" WHERE away_team_goal > home_team_goal AND "away_player_5" IS NOT NULL
UNION ALL SELECT "away_player_6" FROM "Match" WHERE away_team_goal > home_team_goal AND "away_player_6" IS NOT NULL
UNION ALL SELECT "away_player_7" FROM "Match" WHERE away_team_goal > home_team_goal AND "away_player_7" IS NOT NULL
UNION ALL SELECT "away_player_8" FROM "Match" WHERE away_team_goal > home_team_goal AND "away_player_8" IS NOT NULL
UNION ALL SELECT "away_player_9" FROM "Match" WHERE away_team_goal > home_team_goal AND "away_player_9" IS NOT NULL
UNION ALL SELECT "away_player_10" FROM "Match" WHERE away_team_goal > home_team_goal AND "away_player_10" IS NOT NULL
UNION ALL SELECT "away_player_11" FROM "Match" WHERE away_team_goal > home_team_goal AND "away_player_11" IS NOT NULL
),
loser_appearances AS (
      SELECT "home_player_1" AS player_id FROM "Match" WHERE home_team_goal < away_team_goal AND "home_player_1" IS NOT NULL
UNION ALL SELECT "home_player_2" FROM "Match" WHERE home_team_goal < away_team_goal AND "home_player_2" IS NOT NULL
UNION ALL SELECT "home_player_3" FROM "Match" WHERE home_team_goal < away_team_goal AND "home_player_3" IS NOT NULL
UNION ALL SELECT "home_player_4" FROM "Match" WHERE home_team_goal < away_team_goal AND "home_player_4" IS NOT NULL
UNION ALL SELECT "home_player_5" FROM "Match" WHERE home_team_goal < away_team_goal AND "home_player_5" IS NOT NULL
UNION ALL SELECT "home_player_6" FROM "Match" WHERE home_team_goal < away_team_goal AND "home_player_6" IS NOT NULL
UNION ALL SELECT "home_player_7" FROM "Match" WHERE home_team_goal < away_team_goal AND "home_player_7" IS NOT NULL
UNION ALL SELECT "home_player_8" FROM "Match" WHERE home_team_goal < away_team_goal AND "home_player_8" IS NOT NULL
UNION ALL SELECT "home_player_9" FROM "Match" WHERE home_team_goal < away_team_goal AND "home_player_9" IS NOT NULL
UNION ALL SELECT "home_player_10" FROM "Match" WHERE home_team_goal < away_team_goal AND "home_player_10" IS NOT NULL
UNION ALL SELECT "home_player_11" FROM "Match" WHERE home_team_goal < away_team_goal AND "home_player_11" IS NOT NULL
UNION ALL SELECT "away_player_1" FROM "Match" WHERE away_team_goal < home_team_goal AND "away_player_1" IS NOT NULL
UNION ALL SELECT "away_player_2" FROM "Match" WHERE away_team_goal < home_team_goal AND "away_player_2" IS NOT NULL
UNION ALL SELECT "away_player_3" FROM "Match" WHERE away_team_goal < home_team_goal AND "away_player_3" IS NOT NULL
UNION ALL SELECT "away_player_4" FROM "Match" WHERE away_team_goal < home_team_goal AND "away_player_4" IS NOT NULL
UNION ALL SELECT "away_player_5" FROM "Match" WHERE away_team_goal < home_team_goal AND "away_player_5" IS NOT NULL
UNION ALL SELECT "away_player_6" FROM "Match" WHERE away_team_goal < home_team_goal AND "away_player_6" IS NOT NULL
UNION ALL SELECT "away_player_7" FROM "Match" WHERE away_team_goal < home_team_goal AND "away_player_7" IS NOT NULL
UNION ALL SELECT "away_player_8" FROM "Match" WHERE away_team_goal < home_team_goal AND "away_player_8" IS NOT NULL
UNION ALL SELECT "away_player_9" FROM "Match" WHERE away_team_goal < home_team_goal AND "away_player_9" IS NOT NULL
UNION ALL SELECT "away_player_10" FROM "Match" WHERE away_team_goal < home_team_goal AND "away_player_10" IS NOT NULL
UNION ALL SELECT "away_player_11" FROM "Match" WHERE away_team_goal < home_team_goal AND "away_player_11" IS NOT NULL
),
win_totals AS (
    SELECT player_id, COUNT(*) AS total_matches
    FROM winner_appearances
    GROUP BY player_id
),
loss_totals AS (
    SELECT player_id, COUNT(*) AS total_matches
    FROM loser_appearances
    GROUP BY player_id
),
max_win AS (
    SELECT player_id, total_matches
    FROM win_totals
    ORDER BY total_matches DESC
    LIMIT 1
),
max_loss AS (
    SELECT player_id, total_matches
    FROM loss_totals
    ORDER BY total_matches DESC
    LIMIT 1
)
SELECT p.player_name,
       'win' AS match_outcome,
       mw.total_matches
FROM max_win mw
JOIN "Player" p ON p.player_api_id = mw.player_id
UNION ALL
SELECT p.player_name,
       'loss',
       ml.total_matches
FROM max_loss ml
JOIN "Player" p ON p.player_api_id = ml.player_id;