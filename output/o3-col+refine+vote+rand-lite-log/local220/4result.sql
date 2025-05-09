WITH
/* ---------- winning appearances per player ---------- */
win_player_counts AS (
    SELECT player_api_id, COUNT(*) AS win_count
    FROM (
        /* players on the HOME side of a win */
        SELECT home_player_1  AS player_api_id FROM "Match" WHERE home_team_goal > away_team_goal AND home_player_1  IS NOT NULL UNION ALL
        SELECT home_player_2  AS player_api_id FROM "Match" WHERE home_team_goal > away_team_goal AND home_player_2  IS NOT NULL UNION ALL
        SELECT home_player_3  AS player_api_id FROM "Match" WHERE home_team_goal > away_team_goal AND home_player_3  IS NOT NULL UNION ALL
        SELECT home_player_4  AS player_api_id FROM "Match" WHERE home_team_goal > away_team_goal AND home_player_4  IS NOT NULL UNION ALL
        SELECT home_player_5  AS player_api_id FROM "Match" WHERE home_team_goal > away_team_goal AND home_player_5  IS NOT NULL UNION ALL
        SELECT home_player_6  AS player_api_id FROM "Match" WHERE home_team_goal > away_team_goal AND home_player_6  IS NOT NULL UNION ALL
        SELECT home_player_7  AS player_api_id FROM "Match" WHERE home_team_goal > away_team_goal AND home_player_7  IS NOT NULL UNION ALL
        SELECT home_player_8  AS player_api_id FROM "Match" WHERE home_team_goal > away_team_goal AND home_player_8  IS NOT NULL UNION ALL
        SELECT home_player_9  AS player_api_id FROM "Match" WHERE home_team_goal > away_team_goal AND home_player_9  IS NOT NULL UNION ALL
        SELECT home_player_10 AS player_api_id FROM "Match" WHERE home_team_goal > away_team_goal AND home_player_10 IS NOT NULL UNION ALL
        SELECT home_player_11 AS player_api_id FROM "Match" WHERE home_team_goal > away_team_goal AND home_player_11 IS NOT NULL UNION ALL

        /* players on the AWAY side of a win */
        SELECT away_player_1  AS player_api_id FROM "Match" WHERE away_team_goal > home_team_goal AND away_player_1  IS NOT NULL UNION ALL
        SELECT away_player_2  AS player_api_id FROM "Match" WHERE away_team_goal > home_team_goal AND away_player_2  IS NOT NULL UNION ALL
        SELECT away_player_3  AS player_api_id FROM "Match" WHERE away_team_goal > home_team_goal AND away_player_3  IS NOT NULL UNION ALL
        SELECT away_player_4  AS player_api_id FROM "Match" WHERE away_team_goal > home_team_goal AND away_player_4  IS NOT NULL UNION ALL
        SELECT away_player_5  AS player_api_id FROM "Match" WHERE away_team_goal > home_team_goal AND away_player_5  IS NOT NULL UNION ALL
        SELECT away_player_6  AS player_api_id FROM "Match" WHERE away_team_goal > home_team_goal AND away_player_6  IS NOT NULL UNION ALL
        SELECT away_player_7  AS player_api_id FROM "Match" WHERE away_team_goal > home_team_goal AND away_player_7  IS NOT NULL UNION ALL
        SELECT away_player_8  AS player_api_id FROM "Match" WHERE away_team_goal > home_team_goal AND away_player_8  IS NOT NULL UNION ALL
        SELECT away_player_9  AS player_api_id FROM "Match" WHERE away_team_goal > home_team_goal AND away_player_9  IS NOT NULL UNION ALL
        SELECT away_player_10 AS player_api_id FROM "Match" WHERE away_team_goal > home_team_goal AND away_player_10 IS NOT NULL UNION ALL
        SELECT away_player_11 AS player_api_id FROM "Match" WHERE away_team_goal > home_team_goal AND away_player_11 IS NOT NULL
    )
    GROUP BY player_api_id
),

/* ---------- losing appearances per player ---------- */
loss_player_counts AS (
    SELECT player_api_id, COUNT(*) AS loss_count
    FROM (
        /* players on the HOME side of a loss */
        SELECT home_player_1  AS player_api_id FROM "Match" WHERE home_team_goal < away_team_goal AND home_player_1  IS NOT NULL UNION ALL
        SELECT home_player_2  AS player_api_id FROM "Match" WHERE home_team_goal < away_team_goal AND home_player_2  IS NOT NULL UNION ALL
        SELECT home_player_3  AS player_api_id FROM "Match" WHERE home_team_goal < away_team_goal AND home_player_3  IS NOT NULL UNION ALL
        SELECT home_player_4  AS player_api_id FROM "Match" WHERE home_team_goal < away_team_goal AND home_player_4  IS NOT NULL UNION ALL
        SELECT home_player_5  AS player_api_id FROM "Match" WHERE home_team_goal < away_team_goal AND home_player_5  IS NOT NULL UNION ALL
        SELECT home_player_6  AS player_api_id FROM "Match" WHERE home_team_goal < away_team_goal AND home_player_6  IS NOT NULL UNION ALL
        SELECT home_player_7  AS player_api_id FROM "Match" WHERE home_team_goal < away_team_goal AND home_player_7  IS NOT NULL UNION ALL
        SELECT home_player_8  AS player_api_id FROM "Match" WHERE home_team_goal < away_team_goal AND home_player_8  IS NOT NULL UNION ALL
        SELECT home_player_9  AS player_api_id FROM "Match" WHERE home_team_goal < away_team_goal AND home_player_9  IS NOT NULL UNION ALL
        SELECT home_player_10 AS player_api_id FROM "Match" WHERE home_team_goal < away_team_goal AND home_player_10 IS NOT NULL UNION ALL
        SELECT home_player_11 AS player_api_id FROM "Match" WHERE home_team_goal < away_team_goal AND home_player_11 IS NOT NULL UNION ALL

        /* players on the AWAY side of a loss */
        SELECT away_player_1  AS player_api_id FROM "Match" WHERE away_team_goal < home_team_goal AND away_player_1  IS NOT NULL UNION ALL
        SELECT away_player_2  AS player_api_id FROM "Match" WHERE away_team_goal < home_team_goal AND away_player_2  IS NOT NULL UNION ALL
        SELECT away_player_3  AS player_api_id FROM "Match" WHERE away_team_goal < home_team_goal AND away_player_3  IS NOT NULL UNION ALL
        SELECT away_player_4  AS player_api_id FROM "Match" WHERE away_team_goal < home_team_goal AND away_player_4  IS NOT NULL UNION ALL
        SELECT away_player_5  AS player_api_id FROM "Match" WHERE away_team_goal < home_team_goal AND away_player_5  IS NOT NULL UNION ALL
        SELECT away_player_6  AS player_api_id FROM "Match" WHERE away_team_goal < home_team_goal AND away_player_6  IS NOT NULL UNION ALL
        SELECT away_player_7  AS player_api_id FROM "Match" WHERE away_team_goal < home_team_goal AND away_player_7  IS NOT NULL UNION ALL
        SELECT away_player_8  AS player_api_id FROM "Match" WHERE away_team_goal < home_team_goal AND away_player_8  IS NOT NULL UNION ALL
        SELECT away_player_9  AS player_api_id FROM "Match" WHERE away_team_goal < home_team_goal AND away_player_9  IS NOT NULL UNION ALL
        SELECT away_player_10 AS player_api_id FROM "Match" WHERE away_team_goal < home_team_goal AND away_player_10 IS NOT NULL UNION ALL
        SELECT away_player_11 AS player_api_id FROM "Match" WHERE away_team_goal < home_team_goal AND away_player_11 IS NOT NULL
    )
    GROUP BY player_api_id
),

/* ---------- rows holding the maximum counts ---------- */
max_win AS (
    SELECT player_api_id, win_count
    FROM win_player_counts
    ORDER BY win_count DESC
    LIMIT 1
),
max_loss AS (
    SELECT player_api_id, loss_count
    FROM loss_player_counts
    ORDER BY loss_count DESC
    LIMIT 1
)

/* ---------- final output ---------- */
SELECT 'most_wins' AS record_type,
       p.player_name,
       mw.win_count AS match_count
FROM max_win mw
JOIN "Player" p ON p.player_api_id = mw.player_api_id

UNION ALL

SELECT 'most_losses',
       p.player_name,
       ml.loss_count
FROM max_loss ml
JOIN "Player" p ON p.player_api_id = ml.player_api_id

ORDER BY record_type;