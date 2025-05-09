/*  Most-winning vs. most-losing players (draws ignored, NULL slots ignored) */
WITH
/* ---------------- winners ---------------- */
win_players AS (
    /* home-side winners */
    SELECT home_player_1 AS pid FROM Match WHERE home_team_goal > away_team_goal AND home_player_1 IS NOT NULL UNION ALL
    SELECT home_player_2 FROM Match WHERE home_team_goal > away_team_goal AND home_player_2 IS NOT NULL UNION ALL
    SELECT home_player_3 FROM Match WHERE home_team_goal > away_team_goal AND home_player_3 IS NOT NULL UNION ALL
    SELECT home_player_4 FROM Match WHERE home_team_goal > away_team_goal AND home_player_4 IS NOT NULL UNION ALL
    SELECT home_player_5 FROM Match WHERE home_team_goal > away_team_goal AND home_player_5 IS NOT NULL UNION ALL
    SELECT home_player_6 FROM Match WHERE home_team_goal > away_team_goal AND home_player_6 IS NOT NULL UNION ALL
    SELECT home_player_7 FROM Match WHERE home_team_goal > away_team_goal AND home_player_7 IS NOT NULL UNION ALL
    SELECT home_player_8 FROM Match WHERE home_team_goal > away_team_goal AND home_player_8 IS NOT NULL UNION ALL
    SELECT home_player_9 FROM Match WHERE home_team_goal > away_team_goal AND home_player_9 IS NOT NULL UNION ALL
    SELECT home_player_10 FROM Match WHERE home_team_goal > away_team_goal AND home_player_10 IS NOT NULL UNION ALL
    SELECT home_player_11 FROM Match WHERE home_team_goal > away_team_goal AND home_player_11 IS NOT NULL UNION ALL
    /* away-side winners */
    SELECT away_player_1 FROM Match WHERE away_team_goal > home_team_goal AND away_player_1 IS NOT NULL UNION ALL
    SELECT away_player_2 FROM Match WHERE away_team_goal > home_team_goal AND away_player_2 IS NOT NULL UNION ALL
    SELECT away_player_3 FROM Match WHERE away_team_goal > home_team_goal AND away_player_3 IS NOT NULL UNION ALL
    SELECT away_player_4 FROM Match WHERE away_team_goal > home_team_goal AND away_player_4 IS NOT NULL UNION ALL
    SELECT away_player_5 FROM Match WHERE away_team_goal > home_team_goal AND away_player_5 IS NOT NULL UNION ALL
    SELECT away_player_6 FROM Match WHERE away_team_goal > home_team_goal AND away_player_6 IS NOT NULL UNION ALL
    SELECT away_player_7 FROM Match WHERE away_team_goal > home_team_goal AND away_player_7 IS NOT NULL UNION ALL
    SELECT away_player_8 FROM Match WHERE away_team_goal > home_team_goal AND away_player_8 IS NOT NULL UNION ALL
    SELECT away_player_9 FROM Match WHERE away_team_goal > home_team_goal AND away_player_9 IS NOT NULL UNION ALL
    SELECT away_player_10 FROM Match WHERE away_team_goal > home_team_goal AND away_player_10 IS NOT NULL UNION ALL
    SELECT away_player_11 FROM Match WHERE away_team_goal > home_team_goal AND away_player_11 IS NOT NULL
),
win_counts AS (
    SELECT pid AS player_api_id, COUNT(*) AS win_matches
    FROM   win_players
    GROUP  BY pid
),
top_winner AS (
    SELECT player_api_id, win_matches
    FROM   win_counts
    ORDER  BY win_matches DESC
    LIMIT  1
),

/* ---------------- losers ---------------- */
lose_players AS (
    /* home-side losers */
    SELECT home_player_1 AS pid FROM Match WHERE home_team_goal < away_team_goal AND home_player_1 IS NOT NULL UNION ALL
    SELECT home_player_2 FROM Match WHERE home_team_goal < away_team_goal AND home_player_2 IS NOT NULL UNION ALL
    SELECT home_player_3 FROM Match WHERE home_team_goal < away_team_goal AND home_player_3 IS NOT NULL UNION ALL
    SELECT home_player_4 FROM Match WHERE home_team_goal < away_team_goal AND home_player_4 IS NOT NULL UNION ALL
    SELECT home_player_5 FROM Match WHERE home_team_goal < away_team_goal AND home_player_5 IS NOT NULL UNION ALL
    SELECT home_player_6 FROM Match WHERE home_team_goal < away_team_goal AND home_player_6 IS NOT NULL UNION ALL
    SELECT home_player_7 FROM Match WHERE home_team_goal < away_team_goal AND home_player_7 IS NOT NULL UNION ALL
    SELECT home_player_8 FROM Match WHERE home_team_goal < away_team_goal AND home_player_8 IS NOT NULL UNION ALL
    SELECT home_player_9 FROM Match WHERE home_team_goal < away_team_goal AND home_player_9 IS NOT NULL UNION ALL
    SELECT home_player_10 FROM Match WHERE home_team_goal < away_team_goal AND home_player_10 IS NOT NULL UNION ALL
    SELECT home_player_11 FROM Match WHERE home_team_goal < away_team_goal AND home_player_11 IS NOT NULL UNION ALL
    /* away-side losers */
    SELECT away_player_1 FROM Match WHERE away_team_goal < home_team_goal AND away_player_1 IS NOT NULL UNION ALL
    SELECT away_player_2 FROM Match WHERE away_team_goal < home_team_goal AND away_player_2 IS NOT NULL UNION ALL
    SELECT away_player_3 FROM Match WHERE away_team_goal < home_team_goal AND away_player_3 IS NOT NULL UNION ALL
    SELECT away_player_4 FROM Match WHERE away_team_goal < home_team_goal AND away_player_4 IS NOT NULL UNION ALL
    SELECT away_player_5 FROM Match WHERE away_team_goal < home_team_goal AND away_player_5 IS NOT NULL UNION ALL
    SELECT away_player_6 FROM Match WHERE away_team_goal < home_team_goal AND away_player_6 IS NOT NULL UNION ALL
    SELECT away_player_7 FROM Match WHERE away_team_goal < home_team_goal AND away_player_7 IS NOT NULL UNION ALL
    SELECT away_player_8 FROM Match WHERE away_team_goal < home_team_goal AND away_player_8 IS NOT NULL UNION ALL
    SELECT away_player_9 FROM Match WHERE away_team_goal < home_team_goal AND away_player_9 IS NOT NULL UNION ALL
    SELECT away_player_10 FROM Match WHERE away_team_goal < home_team_goal AND away_player_10 IS NOT NULL UNION ALL
    SELECT away_player_11 FROM Match WHERE away_team_goal < home_team_goal AND away_player_11 IS NOT NULL
),
lose_counts AS (
    SELECT pid AS player_api_id, COUNT(*) AS loss_matches
    FROM   lose_players
    GROUP  BY pid
),
top_loser AS (
    SELECT player_api_id, loss_matches
    FROM   lose_counts
    ORDER  BY loss_matches DESC
    LIMIT  1
)

/* ------------- final output ------------- */
SELECT 'most_wins'  AS category,
       p.player_name,
       t.win_matches AS matches
FROM   top_winner t
JOIN   Player      p ON p.player_api_id = t.player_api_id

UNION ALL

SELECT 'most_losses',
       p.player_name,
       t.loss_matches
FROM   top_loser  t
JOIN   Player     p ON p.player_api_id = t.player_api_id;