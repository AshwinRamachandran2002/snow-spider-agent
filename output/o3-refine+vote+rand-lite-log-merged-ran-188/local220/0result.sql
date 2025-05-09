WITH player_matches AS (
    SELECT id AS match_id, home_player_1 AS player_api_id, 'home'  AS side FROM "Match" WHERE home_player_1 IS NOT NULL
    UNION ALL SELECT id, home_player_2, 'home' FROM "Match" WHERE home_player_2 IS NOT NULL
    UNION ALL SELECT id, home_player_3, 'home' FROM "Match" WHERE home_player_3 IS NOT NULL
    UNION ALL SELECT id, home_player_4, 'home' FROM "Match" WHERE home_player_4 IS NOT NULL
    UNION ALL SELECT id, home_player_5, 'home' FROM "Match" WHERE home_player_5 IS NOT NULL
    UNION ALL SELECT id, home_player_6, 'home' FROM "Match" WHERE home_player_6 IS NOT NULL
    UNION ALL SELECT id, home_player_7, 'home' FROM "Match" WHERE home_player_7 IS NOT NULL
    UNION ALL SELECT id, home_player_8, 'home' FROM "Match" WHERE home_player_8 IS NOT NULL
    UNION ALL SELECT id, home_player_9, 'home' FROM "Match" WHERE home_player_9 IS NOT NULL
    UNION ALL SELECT id, home_player_10,'home' FROM "Match" WHERE home_player_10 IS NOT NULL
    UNION ALL SELECT id, home_player_11,'home' FROM "Match" WHERE home_player_11 IS NOT NULL
    UNION ALL SELECT id, away_player_1 AS player_api_id, 'away' AS side FROM "Match" WHERE away_player_1 IS NOT NULL
    UNION ALL SELECT id, away_player_2, 'away' FROM "Match" WHERE away_player_2 IS NOT NULL
    UNION ALL SELECT id, away_player_3, 'away' FROM "Match" WHERE away_player_3 IS NOT NULL
    UNION ALL SELECT id, away_player_4, 'away' FROM "Match" WHERE away_player_4 IS NOT NULL
    UNION ALL SELECT id, away_player_5, 'away' FROM "Match" WHERE away_player_5 IS NOT NULL
    UNION ALL SELECT id, away_player_6, 'away' FROM "Match" WHERE away_player_6 IS NOT NULL
    UNION ALL SELECT id, away_player_7, 'away' FROM "Match" WHERE away_player_7 IS NOT NULL
    UNION ALL SELECT id, away_player_8, 'away' FROM "Match" WHERE away_player_8 IS NOT NULL
    UNION ALL SELECT id, away_player_9, 'away' FROM "Match" WHERE away_player_9 IS NOT NULL
    UNION ALL SELECT id, away_player_10,'away' FROM "Match" WHERE away_player_10 IS NOT NULL
    UNION ALL SELECT id, away_player_11,'away' FROM "Match" WHERE away_player_11 IS NOT NULL
),
player_results AS (
    SELECT
        pm.player_api_id,
        CASE 
            WHEN (pm.side = 'home' AND m.home_team_goal  > m.away_team_goal) OR
                 (pm.side = 'away' AND m.away_team_goal  > m.home_team_goal) THEN 1 ELSE 0 END AS win,
        CASE 
            WHEN (pm.side = 'home' AND m.home_team_goal  < m.away_team_goal) OR
                 (pm.side = 'away' AND m.away_team_goal  < m.home_team_goal) THEN 1 ELSE 0 END AS loss
    FROM player_matches pm
    JOIN "Match" m ON m.id = pm.match_id
    WHERE m.home_team_goal <> m.away_team_goal            -- exclude draws
),
player_totals AS (
    SELECT
        player_api_id,
        SUM(win)  AS wins,
        SUM(loss) AS losses
    FROM player_results
    GROUP BY player_api_id
),
max_win AS (
    SELECT player_api_id, wins  AS cnt 
    FROM player_totals 
    ORDER BY wins DESC, player_api_id ASC 
    LIMIT 1
),
max_loss AS (
    SELECT player_api_id, losses AS cnt
    FROM player_totals 
    ORDER BY losses DESC, player_api_id ASC 
    LIMIT 1
)
SELECT 'Most Wins'   AS category,
       p.player_name AS player,
       mw.cnt        AS matches
FROM max_win mw
JOIN "Player" p ON p.player_api_id = mw.player_api_id
UNION ALL
SELECT 'Most Losses',
       p.player_name,
       ml.cnt
FROM max_loss ml
JOIN "Player" p ON p.player_api_id = ml.player_api_id;