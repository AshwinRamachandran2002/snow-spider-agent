WITH player_team_goals AS (
    /* home team players */
    SELECT id AS match_id, home_team_api_id AS team_api_id,
           home_team_goal AS gf, away_team_goal AS ga, home_player_1 AS player_id
    FROM Match WHERE home_player_1 IS NOT NULL
    UNION ALL SELECT id, home_team_api_id, home_team_goal, away_team_goal, home_player_2  FROM Match WHERE home_player_2  IS NOT NULL
    UNION ALL SELECT id, home_team_api_id, home_team_goal, away_team_goal, home_player_3  FROM Match WHERE home_player_3  IS NOT NULL
    UNION ALL SELECT id, home_team_api_id, home_team_goal, away_team_goal, home_player_4  FROM Match WHERE home_player_4  IS NOT NULL
    UNION ALL SELECT id, home_team_api_id, home_team_goal, away_team_goal, home_player_5  FROM Match WHERE home_player_5  IS NOT NULL
    UNION ALL SELECT id, home_team_api_id, home_team_goal, away_team_goal, home_player_6  FROM Match WHERE home_player_6  IS NOT NULL
    UNION ALL SELECT id, home_team_api_id, home_team_goal, away_team_goal, home_player_7  FROM Match WHERE home_player_7  IS NOT NULL
    UNION ALL SELECT id, home_team_api_id, home_team_goal, away_team_goal, home_player_8  FROM Match WHERE home_player_8  IS NOT NULL
    UNION ALL SELECT id, home_team_api_id, home_team_goal, away_team_goal, home_player_9  FROM Match WHERE home_player_9  IS NOT NULL
    UNION ALL SELECT id, home_team_api_id, home_team_goal, away_team_goal, home_player_10 FROM Match WHERE home_player_10 IS NOT NULL
    UNION ALL SELECT id, home_team_api_id, home_team_goal, away_team_goal, home_player_11 FROM Match WHERE home_player_11 IS NOT NULL
    /* away team players */
    UNION ALL SELECT id, away_team_api_id, away_team_goal, home_team_goal, away_player_1  FROM Match WHERE away_player_1  IS NOT NULL
    UNION ALL SELECT id, away_team_api_id, away_team_goal, home_team_goal, away_player_2  FROM Match WHERE away_player_2  IS NOT NULL
    UNION ALL SELECT id, away_team_api_id, away_team_goal, home_team_goal, away_player_3  FROM Match WHERE away_player_3  IS NOT NULL
    UNION ALL SELECT id, away_team_api_id, away_team_goal, home_team_goal, away_player_4  FROM Match WHERE away_player_4  IS NOT NULL
    UNION ALL SELECT id, away_team_api_id, away_team_goal, home_team_goal, away_player_5  FROM Match WHERE away_player_5  IS NOT NULL
    UNION ALL SELECT id, away_team_api_id, away_team_goal, home_team_goal, away_player_6  FROM Match WHERE away_player_6  IS NOT NULL
    UNION ALL SELECT id, away_team_api_id, away_team_goal, home_team_goal, away_player_7  FROM Match WHERE away_player_7  IS NOT NULL
    UNION ALL SELECT id, away_team_api_id, away_team_goal, home_team_goal, away_player_8  FROM Match WHERE away_player_8  IS NOT NULL
    UNION ALL SELECT id, away_team_api_id, away_team_goal, home_team_goal, away_player_9  FROM Match WHERE away_player_9  IS NOT NULL
    UNION ALL SELECT id, away_team_api_id, away_team_goal, home_team_goal, away_player_10 FROM Match WHERE away_player_10 IS NOT NULL
    UNION ALL SELECT id, away_team_api_id, away_team_goal, home_team_goal, away_player_11 FROM Match WHERE away_player_11 IS NOT NULL
),
player_results AS (
    SELECT player_id,
           CASE
               WHEN gf > ga THEN 'win'
               WHEN gf < ga THEN 'loss'
           END AS result
    FROM player_team_goals
    WHERE gf <> ga                             -- exclude draws
),
win_counts AS (
    SELECT player_id, COUNT(*) AS cnt
    FROM player_results
    WHERE result = 'win'
    GROUP BY player_id
),
loss_counts AS (
    SELECT player_id, COUNT(*) AS cnt
    FROM player_results
    WHERE result = 'loss'
    GROUP BY player_id
),
max_win AS (
    SELECT player_id, cnt AS match_count
    FROM win_counts
    ORDER BY cnt DESC, player_id
    LIMIT 1
),
max_loss AS (
    SELECT player_id, cnt AS match_count
    FROM loss_counts
    ORDER BY cnt DESC, player_id
    LIMIT 1
)
SELECT 'highest_wins'  AS category, Player.player_name, match_count
FROM max_win
JOIN Player ON Player.player_api_id = max_win.player_id
UNION ALL
SELECT 'highest_losses', Player.player_name, match_count
FROM max_loss
JOIN Player ON Player.player_api_id = max_loss.player_id;