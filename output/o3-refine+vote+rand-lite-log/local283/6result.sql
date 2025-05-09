WITH
-- 1. Give every team in every match the points it earned
match_points AS (
    SELECT
        season,
        league_id,
        home_team_api_id AS team_api_id,
        CASE
            WHEN home_team_goal > away_team_goal THEN 3
            WHEN home_team_goal = away_team_goal THEN 1
            ELSE 0
        END AS pts
    FROM "Match"
    
    UNION ALL
    
    SELECT
        season,
        league_id,
        away_team_api_id,
        CASE
            WHEN away_team_goal > home_team_goal THEN 3
            WHEN away_team_goal = home_team_goal THEN 1
            ELSE 0
        END
    FROM "Match"
),

-- 2. Total points per team, per season, per league
season_totals AS (
    SELECT
        season,
        league_id,
        team_api_id,
        SUM(pts) AS total_points
    FROM match_points
    GROUP BY season, league_id, team_api_id
),

-- 3. Rank teams inside every (season, league) by points
ranked AS (
    SELECT
        season,
        league_id,
        team_api_id,
        total_points,
        ROW_NUMBER() OVER (
            PARTITION BY season, league_id
            ORDER BY total_points DESC, team_api_id ASC
        ) AS rn
    FROM season_totals
)

-- 4. Keep only the champion (rn = 1) for every season & league
SELECT
    T.team_long_name     AS team_name,
    L.name               AS league_name,
    C.name               AS country_name,
    r.season,
    r.total_points
FROM ranked r
JOIN Team    T ON r.team_api_id = T.team_api_id
JOIN League  L ON r.league_id   = L.id
JOIN Country C ON L.country_id  = C.id
WHERE r.rn = 1
ORDER BY r.season, country_name, league_name, team_name;