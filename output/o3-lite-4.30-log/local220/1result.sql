WITH
win_players AS (
    SELECT home_player_1  AS player_api_id FROM "Match" WHERE home_team_goal > away_team_goal AND home_player_1  IS NOT NULL
    UNION ALL SELECT home_player_2  FROM "Match" WHERE home_team_goal > away_team_goal AND home_player_2  IS NOT NULL
    UNION ALL SELECT home_player_3  FROM "Match" WHERE home_team_goal > away_team_goal AND home_player_3  IS NOT NULL
    UNION ALL SELECT home_player_4  FROM "Match" WHERE home_team_goal > away_team_goal AND home_player_4  IS NOT NULL
    UNION ALL SELECT home_player_5  FROM "Match" WHERE home_team_goal > away_team_goal AND home_player_5  IS NOT NULL
    UNION ALL SELECT home_player_6  FROM "Match" WHERE home_team_goal > away_team_goal AND home_player_6  IS NOT NULL
    UNION ALL SELECT home_player_7  FROM "Match" WHERE home_team_goal > away_team_goal AND home_player_7  IS NOT NULL
    UNION ALL SELECT home_player_8  FROM "Match" WHERE home_team_goal > away_team_goal AND home_player_8  IS NOT NULL
    UNION ALL SELECT home_player_9  FROM "Match" WHERE home_team_goal > away_team_goal AND home_player_9  IS NOT NULL
    UNION ALL SELECT home_player_10 FROM "Match" WHERE home_team_goal > away_team_goal AND home_player_10 IS NOT NULL
    UNION ALL SELECT home_player_11 FROM "Match" WHERE home_team_goal > away_team_goal AND home_player_11 IS NOT NULL
    UNION ALL
    SELECT away_player_1  FROM "Match" WHERE away_team_goal > home_team_goal AND away_player_1  IS NOT NULL
    UNION ALL SELECT away_player_2  FROM "Match" WHERE away_team_goal > home_team_goal AND away_player_2  IS NOT NULL
    UNION ALL SELECT away_player_3  FROM "Match" WHERE away_team_goal > home_team_goal AND away_player_3  IS NOT NULL
    UNION ALL SELECT away_player_4  FROM "Match" WHERE away_team_goal > home_team_goal AND away_player_4  IS NOT NULL
    UNION ALL SELECT away_player_5  FROM "Match" WHERE away_team_goal > home_team_goal AND away_player_5  IS NOT NULL
    UNION ALL SELECT away_player_6  FROM "Match" WHERE away_team_goal > home_team_goal AND away_player_6  IS NOT NULL
    UNION ALL SELECT away_player_7  FROM "Match" WHERE away_team_goal > home_team_goal AND away_player_7  IS NOT NULL
    UNION ALL SELECT away_player_8  FROM "Match" WHERE away_team_goal > home_team_goal AND away_player_8  IS NOT NULL
    UNION ALL SELECT away_player_9  FROM "Match" WHERE away_team_goal > home_team_goal AND away_player_9  IS NOT NULL
    UNION ALL SELECT away_player_10 FROM "Match" WHERE away_team_goal > home_team_goal AND away_player_10 IS NOT NULL
    UNION ALL SELECT away_player_11 FROM "Match" WHERE away_team_goal > home_team_goal AND away_player_11 IS NOT NULL
),
loss_players AS (
    SELECT home_player_1  AS player_api_id FROM "Match" WHERE home_team_goal < away_team_goal AND home_player_1  IS NOT NULL
    UNION ALL SELECT home_player_2  FROM "Match" WHERE home_team_goal < away_team_goal AND home_player_2  IS NOT NULL
    UNION ALL SELECT home_player_3  FROM "Match" WHERE home_team_goal < away_team_goal AND home_player_3  IS NOT NULL
    UNION ALL SELECT home_player_4  FROM "Match" WHERE home_team_goal < away_team_goal AND home_player_4  IS NOT NULL
    UNION ALL SELECT home_player_5  FROM "Match" WHERE home_team_goal < away_team_goal AND home_player_5  IS NOT NULL
    UNION ALL SELECT home_player_6  FROM "Match" WHERE home_team_goal < away_team_goal AND home_player_6  IS NOT NULL
    UNION ALL SELECT home_player_7  FROM "Match" WHERE home_team_goal < away_team_goal AND home_player_7  IS NOT NULL
    UNION ALL SELECT home_player_8  FROM "Match" WHERE home_team_goal < away_team_goal AND home_player_8  IS NOT NULL
    UNION ALL SELECT home_player_9  FROM "Match" WHERE home_team_goal < away_team_goal AND home_player_9  IS NOT NULL
    UNION ALL SELECT home_player_10 FROM "Match" WHERE home_team_goal < away_team_goal AND home_player_10 IS NOT NULL
    UNION ALL SELECT home_player_11 FROM "Match" WHERE home_team_goal < away_team_goal AND home_player_11 IS NOT NULL
    UNION ALL
    SELECT away_player_1  FROM "Match" WHERE away_team_goal < home_team_goal AND away_player_1  IS NOT NULL
    UNION ALL SELECT away_player_2  FROM "Match" WHERE away_team_goal < home_team_goal AND away_player_2  IS NOT NULL
    UNION ALL SELECT away_player_3  FROM "Match" WHERE away_team_goal < home_team_goal AND away_player_3  IS NOT NULL
    UNION ALL SELECT away_player_4  FROM "Match" WHERE away_team_goal < home_team_goal AND away_player_4  IS NOT NULL
    UNION ALL SELECT away_player_5  FROM "Match" WHERE away_team_goal < home_team_goal AND away_player_5  IS NOT NULL
    UNION ALL SELECT away_player_6  FROM "Match" WHERE away_team_goal < home_team_goal AND away_player_6  IS NOT NULL
    UNION ALL SELECT away_player_7  FROM "Match" WHERE away_team_goal < home_team_goal AND away_player_7  IS NOT NULL
    UNION ALL SELECT away_player_8  FROM "Match" WHERE away_team_goal < home_team_goal AND away_player_8  IS NOT NULL
    UNION ALL SELECT away_player_9  FROM "Match" WHERE away_team_goal < home_team_goal AND away_player_9  IS NOT NULL
    UNION ALL SELECT away_player_10 FROM "Match" WHERE away_team_goal < home_team_goal AND away_player_10 IS NOT NULL
    UNION ALL SELECT away_player_11 FROM "Match" WHERE away_team_goal < home_team_goal AND away_player_11 IS NOT NULL
),
wins AS (
    SELECT player_api_id, COUNT(*) AS total_matches
    FROM win_players
    GROUP BY player_api_id
),
losses AS (
    SELECT player_api_id, COUNT(*) AS total_matches
    FROM loss_players
    GROUP BY player_api_id
),
max_win AS (
    SELECT player_api_id, total_matches
    FROM wins
    ORDER BY total_matches DESC, player_api_id
    LIMIT 1
),
max_loss AS (
    SELECT player_api_id, total_matches
    FROM losses
    ORDER BY total_matches DESC, player_api_id
    LIMIT 1
)
SELECT p.player_name, 'win'  AS match_outcome, mw.total_matches
FROM   max_win  mw
JOIN   "Player" p ON p.player_api_id = mw.player_api_id

UNION ALL

SELECT p.player_name, 'loss' AS match_outcome, ml.total_matches
FROM   max_loss ml
JOIN   "Player" p ON p.player_api_id = ml.player_api_id;