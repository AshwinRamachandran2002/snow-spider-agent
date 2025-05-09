WITH home_wins AS (
    SELECT 
        home_team_api_id AS team_api_id,
        COUNT(*) AS wins
    FROM "Match"
    WHERE home_team_goal > away_team_goal
    GROUP BY home_team_api_id
),
away_wins AS (
    SELECT 
        away_team_api_id AS team_api_id,
        COUNT(*) AS wins
    FROM "Match"
    WHERE away_team_goal > home_team_goal
    GROUP BY away_team_api_id
),
all_wins AS (
    SELECT team_api_id, wins FROM home_wins
    UNION ALL
    SELECT team_api_id, wins FROM away_wins
),
total_wins AS (
    SELECT 
        team_api_id,
        SUM(wins) AS total_wins
    FROM all_wins
    GROUP BY team_api_id
)
SELECT 
    Team.team_long_name AS team_name,
    total_wins
FROM total_wins
JOIN Team ON Team.team_api_id = total_wins.team_api_id
ORDER BY total_wins DESC, team_name ASC
LIMIT 10;