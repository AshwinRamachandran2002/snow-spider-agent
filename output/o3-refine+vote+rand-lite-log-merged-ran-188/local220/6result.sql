WITH player_match AS (
        -- -----  home team players -----
        SELECT id AS match_id, home_player_1 AS player_id,
               home_team_goal AS team_goal, away_team_goal AS opp_goal
        FROM "Match"
        UNION ALL SELECT id, home_player_2, home_team_goal, away_team_goal FROM "Match"
        UNION ALL SELECT id, home_player_3, home_team_goal, away_team_goal FROM "Match"
        UNION ALL SELECT id, home_player_4, home_team_goal, away_team_goal FROM "Match"
        UNION ALL SELECT id, home_player_5, home_team_goal, away_team_goal FROM "Match"
        UNION ALL SELECT id, home_player_6, home_team_goal, away_team_goal FROM "Match"
        UNION ALL SELECT id, home_player_7, home_team_goal, away_team_goal FROM "Match"
        UNION ALL SELECT id, home_player_8, home_team_goal, away_team_goal FROM "Match"
        UNION ALL SELECT id, home_player_9, home_team_goal, away_team_goal FROM "Match"
        UNION ALL SELECT id, home_player_10, home_team_goal, away_team_goal FROM "Match"
        UNION ALL SELECT id, home_player_11, home_team_goal, away_team_goal FROM "Match"

        -- -----  away team players -----
        UNION ALL SELECT id, away_player_1, away_team_goal, home_team_goal FROM "Match"
        UNION ALL SELECT id, away_player_2, away_team_goal, home_team_goal FROM "Match"
        UNION ALL SELECT id, away_player_3, away_team_goal, home_team_goal FROM "Match"
        UNION ALL SELECT id, away_player_4, away_team_goal, home_team_goal FROM "Match"
        UNION ALL SELECT id, away_player_5, away_team_goal, home_team_goal FROM "Match"
        UNION ALL SELECT id, away_player_6, away_team_goal, home_team_goal FROM "Match"
        UNION ALL SELECT id, away_player_7, away_team_goal, home_team_goal FROM "Match"
        UNION ALL SELECT id, away_player_8, away_team_goal, home_team_goal FROM "Match"
        UNION ALL SELECT id, away_player_9, away_team_goal, home_team_goal FROM "Match"
        UNION ALL SELECT id, away_player_10, away_team_goal, home_team_goal FROM "Match"
        UNION ALL SELECT id, away_player_11, away_team_goal, home_team_goal FROM "Match"
),
filtered AS (
        SELECT player_id,
               CASE WHEN team_goal > opp_goal THEN 1 ELSE 0 END AS win,
               CASE WHEN team_goal < opp_goal THEN 1 ELSE 0 END AS loss
        FROM   player_match
        WHERE  player_id IS NOT NULL
          AND  team_goal <> opp_goal            -- exclude draws
),
player_stats AS (
        SELECT player_id,
               SUM(win)  AS wins,
               SUM(loss) AS losses
        FROM   filtered
        GROUP BY player_id
),
max_wins AS (
        SELECT player_id, wins
        FROM   player_stats
        ORDER BY wins DESC, player_id
        LIMIT 1
),
max_losses AS (
        SELECT player_id, losses
        FROM   player_stats
        ORDER BY losses DESC, player_id
        LIMIT 1
)
SELECT 'most_wins'  AS category,
       p.player_name,
       ps.wins       AS match_count
FROM   max_wins mw
JOIN   player_stats ps ON ps.player_id = mw.player_id
JOIN   Player        p ON p.player_api_id = mw.player_id

UNION ALL

SELECT 'most_losses',
       p.player_name,
       ps.losses
FROM   max_losses ml
JOIN   player_stats ps ON ps.player_id = ml.player_id
JOIN   Player        p ON p.player_api_id = ml.player_id;