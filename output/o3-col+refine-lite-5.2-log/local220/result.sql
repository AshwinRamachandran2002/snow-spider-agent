/* player with the most victories vs. player with the most defeats */
WITH win_players AS (
    /* every (not‑null) appearance where the player’s team WON */
    SELECT home_player_1 AS player_api_id FROM "Match"
        WHERE home_team_goal > away_team_goal AND home_player_1 IS NOT NULL UNION ALL
    SELECT home_player_2 AS player_api_id FROM "Match"
        WHERE home_team_goal > away_team_goal AND home_player_2 IS NOT NULL UNION ALL
    SELECT home_player_3 AS player_api_id FROM "Match"
        WHERE home_team_goal > away_team_goal AND home_player_3 IS NOT NULL UNION ALL
    SELECT home_player_4 AS player_api_id FROM "Match"
        WHERE home_team_goal > away_team_goal AND home_player_4 IS NOT NULL UNION ALL
    SELECT home_player_5 AS player_api_id FROM "Match"
        WHERE home_team_goal > away_team_goal AND home_player_5 IS NOT NULL UNION ALL
    SELECT home_player_6 AS player_api_id FROM "Match"
        WHERE home_team_goal > away_team_goal AND home_player_6 IS NOT NULL UNION ALL
    SELECT home_player_7 AS player_api_id FROM "Match"
        WHERE home_team_goal > away_team_goal AND home_player_7 IS NOT NULL UNION ALL
    SELECT home_player_8 AS player_api_id FROM "Match"
        WHERE home_team_goal > away_team_goal AND home_player_8 IS NOT NULL UNION ALL
    SELECT home_player_9 AS player_api_id FROM "Match"
        WHERE home_team_goal > away_team_goal AND home_player_9 IS NOT NULL UNION ALL
    SELECT home_player_10 AS player_api_id FROM "Match"
        WHERE home_team_goal > away_team_goal AND home_player_10 IS NOT NULL UNION ALL
    SELECT home_player_11 AS player_api_id FROM "Match"
        WHERE home_team_goal > away_team_goal AND home_player_11 IS NOT NULL UNION ALL
    SELECT away_player_1 AS player_api_id FROM "Match"
        WHERE away_team_goal > home_team_goal AND away_player_1 IS NOT NULL UNION ALL
    SELECT away_player_2 AS player_api_id FROM "Match"
        WHERE away_team_goal > home_team_goal AND away_player_2 IS NOT NULL UNION ALL
    SELECT away_player_3 AS player_api_id FROM "Match"
        WHERE away_team_goal > home_team_goal AND away_player_3 IS NOT NULL UNION ALL
    SELECT away_player_4 AS player_api_id FROM "Match"
        WHERE away_team_goal > home_team_goal AND away_player_4 IS NOT NULL UNION ALL
    SELECT away_player_5 AS player_api_id FROM "Match"
        WHERE away_team_goal > home_team_goal AND away_player_5 IS NOT NULL UNION ALL
    SELECT away_player_6 AS player_api_id FROM "Match"
        WHERE away_team_goal > home_team_goal AND away_player_6 IS NOT NULL UNION ALL
    SELECT away_player_7 AS player_api_id FROM "Match"
        WHERE away_team_goal > home_team_goal AND away_player_7 IS NOT NULL UNION ALL
    SELECT away_player_8 AS player_api_id FROM "Match"
        WHERE away_team_goal > home_team_goal AND away_player_8 IS NOT NULL UNION ALL
    SELECT away_player_9 AS player_api_id FROM "Match"
        WHERE away_team_goal > home_team_goal AND away_player_9 IS NOT NULL UNION ALL
    SELECT away_player_10 AS player_api_id FROM "Match"
        WHERE away_team_goal > home_team_goal AND away_player_10 IS NOT NULL UNION ALL
    SELECT away_player_11 AS player_api_id FROM "Match"
        WHERE away_team_goal > home_team_goal AND away_player_11 IS NOT NULL
),
loss_players AS (
    /* every (not‑null) appearance where the player’s team LOST */
    SELECT home_player_1 AS player_api_id FROM "Match"
        WHERE home_team_goal < away_team_goal AND home_player_1 IS NOT NULL UNION ALL
    SELECT home_player_2 AS player_api_id FROM "Match"
        WHERE home_team_goal < away_team_goal AND home_player_2 IS NOT NULL UNION ALL
    SELECT home_player_3 AS player_api_id FROM "Match"
        WHERE home_team_goal < away_team_goal AND home_player_3 IS NOT NULL UNION ALL
    SELECT home_player_4 AS player_api_id FROM "Match"
        WHERE home_team_goal < away_team_goal AND home_player_4 IS NOT NULL UNION ALL
    SELECT home_player_5 AS player_api_id FROM "Match"
        WHERE home_team_goal < away_team_goal AND home_player_5 IS NOT NULL UNION ALL
    SELECT home_player_6 AS player_api_id FROM "Match"
        WHERE home_team_goal < away_team_goal AND home_player_6 IS NOT NULL UNION ALL
    SELECT home_player_7 AS player_api_id FROM "Match"
        WHERE home_team_goal < away_team_goal AND home_player_7 IS NOT NULL UNION ALL
    SELECT home_player_8 AS player_api_id FROM "Match"
        WHERE home_team_goal < away_team_goal AND home_player_8 IS NOT NULL UNION ALL
    SELECT home_player_9 AS player_api_id FROM "Match"
        WHERE home_team_goal < away_team_goal AND home_player_9 IS NOT NULL UNION ALL
    SELECT home_player_10 AS player_api_id FROM "Match"
        WHERE home_team_goal < away_team_goal AND home_player_10 IS NOT NULL UNION ALL
    SELECT home_player_11 AS player_api_id FROM "Match"
        WHERE home_team_goal < away_team_goal AND home_player_11 IS NOT NULL UNION ALL
    SELECT away_player_1 AS player_api_id FROM "Match"
        WHERE away_team_goal < home_team_goal AND away_player_1 IS NOT NULL UNION ALL
    SELECT away_player_2 AS player_api_id FROM "Match"
        WHERE away_team_goal < home_team_goal AND away_player_2 IS NOT NULL UNION ALL
    SELECT away_player_3 AS player_api_id FROM "Match"
        WHERE away_team_goal < home_team_goal AND away_player_3 IS NOT NULL UNION ALL
    SELECT away_player_4 AS player_api_id FROM "Match"
        WHERE away_team_goal < home_team_goal AND away_player_4 IS NOT NULL UNION ALL
    SELECT away_player_5 AS player_api_id FROM "Match"
        WHERE away_team_goal < home_team_goal AND away_player_5 IS NOT NULL UNION ALL
    SELECT away_player_6 AS player_api_id FROM "Match"
        WHERE away_team_goal < home_team_goal AND away_player_6 IS NOT NULL UNION ALL
    SELECT away_player_7 AS player_api_id FROM "Match"
        WHERE away_team_goal < home_team_goal AND away_player_7 IS NOT NULL UNION ALL
    SELECT away_player_8 AS player_api_id FROM "Match"
        WHERE away_team_goal < home_team_goal AND away_player_8 IS NOT NULL UNION ALL
    SELECT away_player_9 AS player_api_id FROM "Match"
        WHERE away_team_goal < home_team_goal AND away_player_9 IS NOT NULL UNION ALL
    SELECT away_player_10 AS player_api_id FROM "Match"
        WHERE away_team_goal < home_team_goal AND away_player_10 IS NOT NULL UNION ALL
    SELECT away_player_11 AS player_api_id FROM "Match"
        WHERE away_team_goal < home_team_goal AND away_player_11 IS NOT NULL
),
win_counts AS (
    SELECT player_api_id, COUNT(*) AS total_wins
    FROM win_players
    GROUP BY player_api_id
),
loss_counts AS (
    SELECT player_api_id, COUNT(*) AS total_losses
    FROM loss_players
    GROUP BY player_api_id
),
top_win AS (
    SELECT player_api_id, total_wins
    FROM win_counts
    ORDER BY total_wins DESC, player_api_id
    LIMIT 1
),
top_loss AS (
    SELECT player_api_id, total_losses
    FROM loss_counts
    ORDER BY total_losses DESC, player_api_id
    LIMIT 1
)

SELECT 'Most Winning' AS category,
       p.player_name,
       tw.total_wins AS matches
FROM top_win tw
JOIN "Player" p ON p.player_api_id = tw.player_api_id

UNION ALL

SELECT 'Most Losing',
       p.player_name,
       tl.total_losses
FROM top_loss tl
JOIN "Player" p ON p.player_api_id = tl.player_api_id;