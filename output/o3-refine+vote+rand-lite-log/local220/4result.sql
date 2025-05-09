WITH participation AS (
    -- home side
    SELECT id AS match_id, home_player_1  AS player_api_id,
           home_team_goal AS home_goals, away_team_goal AS away_goals,
           'home' AS side
    FROM "Match"
    UNION ALL  SELECT id, home_player_2 , home_team_goal, away_team_goal, 'home' FROM "Match"
    UNION ALL  SELECT id, home_player_3 , home_team_goal, away_team_goal, 'home' FROM "Match"
    UNION ALL  SELECT id, home_player_4 , home_team_goal, away_team_goal, 'home' FROM "Match"
    UNION ALL  SELECT id, home_player_5 , home_team_goal, away_team_goal, 'home' FROM "Match"
    UNION ALL  SELECT id, home_player_6 , home_team_goal, away_team_goal, 'home' FROM "Match"
    UNION ALL  SELECT id, home_player_7 , home_team_goal, away_team_goal, 'home' FROM "Match"
    UNION ALL  SELECT id, home_player_8 , home_team_goal, away_team_goal, 'home' FROM "Match"
    UNION ALL  SELECT id, home_player_9 , home_team_goal, away_team_goal, 'home' FROM "Match"
    UNION ALL  SELECT id, home_player_10, home_team_goal, away_team_goal, 'home' FROM "Match"
    UNION ALL  SELECT id, home_player_11, home_team_goal, away_team_goal, 'home' FROM "Match"
    -- away side
    UNION ALL  SELECT id, away_player_1 , home_team_goal, away_team_goal, 'away' FROM "Match"
    UNION ALL  SELECT id, away_player_2 , home_team_goal, away_team_goal, 'away' FROM "Match"
    UNION ALL  SELECT id, away_player_3 , home_team_goal, away_team_goal, 'away' FROM "Match"
    UNION ALL  SELECT id, away_player_4 , home_team_goal, away_team_goal, 'away' FROM "Match"
    UNION ALL  SELECT id, away_player_5 , home_team_goal, away_team_goal, 'away' FROM "Match"
    UNION ALL  SELECT id, away_player_6 , home_team_goal, away_team_goal, 'away' FROM "Match"
    UNION ALL  SELECT id, away_player_7 , home_team_goal, away_team_goal, 'away' FROM "Match"
    UNION ALL  SELECT id, away_player_8 , home_team_goal, away_team_goal, 'away' FROM "Match"
    UNION ALL  SELECT id, away_player_9 , home_team_goal, away_team_goal, 'away' FROM "Match"
    UNION ALL  SELECT id, away_player_10, home_team_goal, away_team_goal, 'away' FROM "Match"
    UNION ALL  SELECT id, away_player_11, home_team_goal, away_team_goal, 'away' FROM "Match"
),
results AS (
    SELECT
        player_api_id,
        CASE
            WHEN side = 'home' AND home_goals > away_goals THEN 1
            WHEN side = 'away' AND away_goals > home_goals THEN 1
            ELSE 0
        END AS is_win,
        CASE
            WHEN side = 'home' AND home_goals < away_goals THEN 1
            WHEN side = 'away' AND away_goals < home_goals THEN 1
            ELSE 0
        END AS is_loss
    FROM participation
    WHERE player_api_id IS NOT NULL
      AND home_goals IS NOT NULL
      AND away_goals IS NOT NULL
      AND home_goals <> away_goals          -- exclude draws
),
stats AS (
    SELECT player_api_id,
           SUM(is_win)  AS wins,
           SUM(is_loss) AS losses
    FROM results
    GROUP BY player_api_id
),
most_wins AS (
    SELECT player_api_id, wins
    FROM stats
    ORDER BY wins DESC
    LIMIT 1
),
most_losses AS (
    SELECT player_api_id, losses
    FROM stats
    ORDER BY losses DESC
    LIMIT 1
)
-- final answer: two rows, one for most wins and one for most losses
SELECT 'most_wins'  AS category,
       p.player_name,
       m.wins        AS match_count
FROM most_wins m
JOIN Player p ON p.player_api_id = m.player_api_id

UNION ALL

SELECT 'most_losses',
       p.player_name,
       m.losses
FROM most_losses m
JOIN Player p ON p.player_api_id = m.player_api_id;