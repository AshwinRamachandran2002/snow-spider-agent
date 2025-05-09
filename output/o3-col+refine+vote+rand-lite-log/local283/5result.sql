WITH team_points AS (               -- 1. points table for every team-league-season
    SELECT
        season,
        league_id,
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
        away_team_api_id,
        CASE
            WHEN away_team_goal > home_team_goal THEN 3
            WHEN away_team_goal = home_team_goal THEN 1
            ELSE 0
        END
    FROM "Match"
),
points_summed AS (                  -- 2. sum of points per team
    SELECT
        season,
        league_id,
        team_api_id,
        SUM(points) AS total_points
    FROM team_points
    GROUP BY season, league_id, team_api_id
),
max_points AS (                     -- 3. max points needed to win every league-season
    SELECT
        season,
        league_id,
        MAX(total_points) AS pts_needed
    FROM points_summed
    GROUP BY season, league_id
)
SELECT
    p.season,
    t.team_long_name  AS champion_team,
    l.name            AS league_name,
    c.name            AS country_name,
    p.total_points
FROM points_summed AS p
JOIN max_points   AS m ON  p.season     = m.season
                       AND p.league_id  = m.league_id
                       AND p.total_points = m.pts_needed
JOIN "Team"    AS t ON p.team_api_id = t.team_api_id
JOIN "League"  AS l ON p.league_id   = l.id
JOIN "Country" AS c ON l.country_id  = c.id
ORDER BY p.season, l.id, champion_team;