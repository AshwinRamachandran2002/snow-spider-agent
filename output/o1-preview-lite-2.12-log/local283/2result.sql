WITH team_points AS (
    SELECT
        season,
        league_id,
        country_id,
        home_team_api_id AS team_api_id,
        CASE 
            WHEN home_team_goal > away_team_goal THEN 3
            WHEN home_team_goal = away_team_goal THEN 1
            ELSE 0
        END AS points
    FROM "Match"
    UNION ALL
    SELECT
        season,
        league_id,
        country_id,
        away_team_api_id AS team_api_id,
        CASE 
            WHEN away_team_goal > home_team_goal THEN 3
            WHEN away_team_goal = home_team_goal THEN 1
            ELSE 0
        END AS points
    FROM "Match"
),
team_total_points AS (
    SELECT
        season,
        league_id,
        country_id,
        team_api_id,
        SUM(points) AS total_points
    FROM team_points
    GROUP BY season, league_id, country_id, team_api_id
),
max_points AS (
    SELECT 
        season, 
        league_id, 
        MAX(total_points) AS max_total_points
    FROM team_total_points
    GROUP BY season, league_id
)
SELECT 
    ttp.season AS Season,
    t.team_long_name AS Champion_Team_Name,
    l.name AS League,
    c.name AS Country,
    ttp.total_points AS Total_Points
FROM team_total_points ttp
JOIN max_points mp 
    ON ttp.season = mp.season 
    AND ttp.league_id = mp.league_id 
    AND ttp.total_points = mp.max_total_points
JOIN "Team" t ON ttp.team_api_id = t.team_api_id
JOIN "League" l ON ttp.league_id = l.id
JOIN "Country" c ON ttp.country_id = c.id
ORDER BY ttp.season, l.name;