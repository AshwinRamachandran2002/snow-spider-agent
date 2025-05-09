WITH home AS (
    SELECT
        season,
        home_team_api_id AS team_id,
        SUM(home_team_goal) AS goals
    FROM Match
    GROUP BY season, team_id
),
away AS (
    SELECT
        season,
        away_team_api_id AS team_id,
        SUM(away_team_goal) AS goals
    FROM Match
    GROUP BY season, team_id
),
team_season AS (
    SELECT * FROM home
    UNION ALL
    SELECT * FROM away
),
season_totals AS (
    SELECT
        season,
        team_id,
        SUM(goals) AS season_goals
    FROM team_season
    GROUP BY season, team_id
),
team_best AS (
    SELECT
        team_id,
        MAX(season_goals) AS best_goals
    FROM season_totals
    GROUP BY team_id
),
ordered AS (
    SELECT
        best_goals,
        ROW_NUMBER() OVER (ORDER BY best_goals) AS rn,
        COUNT(*) OVER () AS n
    FROM team_best
)
SELECT
    AVG(best_goals) AS median_highest_season_goals
FROM ordered
WHERE  (n % 2 = 1 AND rn = (n + 1) / 2)
    OR (n % 2 = 0 AND rn IN (n / 2, n / 2 + 1));