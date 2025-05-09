WITH match_points AS (
    /* 1. Give every team points for every match (3‑1‑0 rule) */
    SELECT 
        season,
        league_id,
        home_team_api_id AS team_api_id,
        CASE
            WHEN home_team_goal > away_team_goal THEN 3
            WHEN home_team_goal = away_team_goal THEN 1
            ELSE 0
        END AS pts
    FROM Match
    
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
    FROM Match
),
team_points AS (
    /* 2. Total points per team‑season‑league */
    SELECT
        season,
        league_id,
        team_api_id,
        SUM(pts) AS total_points
    FROM match_points
    GROUP BY season, league_id, team_api_id
),
max_points AS (
    /* 3. Best (max) point total in every league & season */
    SELECT
        season,
        league_id,
        MAX(total_points) AS max_pts
    FROM team_points
    GROUP BY season, league_id
)
SELECT
    tp.season,
    c.name                  AS country,
    l.name                  AS league,
    t.team_long_name        AS champion_team,
    tp.total_points
FROM          team_points tp
JOIN          max_points mp
       ON     tp.season      = mp.season
       AND    tp.league_id   = mp.league_id
       AND    tp.total_points = mp.max_pts
JOIN          League   l ON tp.league_id  = l.id
JOIN          Country  c ON l.country_id = c.id
JOIN          Team     t ON tp.team_api_id = t.team_api_id
ORDER BY
    tp.season,
    country,
    league,
    champion_team;