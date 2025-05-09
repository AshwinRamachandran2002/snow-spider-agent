WITH team_points AS (
    SELECT season, league_id, team_api_id, SUM(points) AS total_points
    FROM (
        SELECT season, league_id, home_team_api_id AS team_api_id,
            CASE
                WHEN home_team_goal > away_team_goal THEN 3
                WHEN home_team_goal = away_team_goal THEN 1
                ELSE 0
            END AS points
        FROM "Match"
        UNION ALL
        SELECT season, league_id, away_team_api_id AS team_api_id,
            CASE
                WHEN away_team_goal > home_team_goal THEN 3
                WHEN away_team_goal = home_team_goal THEN 1
                ELSE 0
            END AS points
        FROM "Match"
    ) AS match_points
    GROUP BY season, league_id, team_api_id
),
max_points AS (
    SELECT season, league_id, MAX(total_points) AS max_total_points
    FROM team_points
    GROUP BY season, league_id
),
champions AS (
    SELECT tp.season, tp.league_id, tp.team_api_id, tp.total_points
    FROM team_points tp
    JOIN max_points mp ON tp.season = mp.season
                        AND tp.league_id = mp.league_id
                        AND tp.total_points = mp.max_total_points
)
SELECT
    c.season AS Season,
    t.team_long_name AS Team_Name,
    l.name AS League_Name,
    co.name AS Country_Name,
    c.total_points AS Total_Points
FROM champions c
JOIN "Team" t ON c.team_api_id = t.team_api_id
JOIN "League" l ON c.league_id = l.id
JOIN "Country" co ON l.country_id = co.id
ORDER BY c.season, l.name;