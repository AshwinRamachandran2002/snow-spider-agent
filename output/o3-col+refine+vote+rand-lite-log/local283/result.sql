WITH team_match_points AS (
    /* 1. Give every team points for every match it plays (home and away) */
    SELECT 
        season,
        league_id,
        home_team_api_id   AS team_api_id,
        CASE 
            WHEN home_team_goal > away_team_goal THEN 3
            WHEN home_team_goal = away_team_goal THEN 1
            ELSE 0
        END                AS points
    FROM Match
    
    UNION ALL
    
    SELECT 
        season,
        league_id,
        away_team_api_id   AS team_api_id,
        CASE 
            WHEN away_team_goal > home_team_goal THEN 3
            WHEN away_team_goal = home_team_goal THEN 1
            ELSE 0
        END                AS points
    FROM Match
),
team_season_points AS (
    /* 2. Aggregate to total points for each team within every season-league */
    SELECT
        season,
        league_id,
        team_api_id,
        SUM(points) AS total_points
    FROM team_match_points
    GROUP BY season, league_id, team_api_id
),
league_best AS (
    /* 3. Find the maximum points obtained in each season-league */
    SELECT
        season,
        league_id,
        MAX(total_points) AS max_points
    FROM team_season_points
    GROUP BY season, league_id
),
champions AS (
    /* 4. Keep only the team(s) whose points equal that maximum */
    SELECT 
        tsp.season,
        tsp.league_id,
        tsp.team_api_id,
        tsp.total_points
    FROM team_season_points AS tsp
    JOIN league_best       AS lb
      ON  tsp.season      = lb.season
      AND tsp.league_id   = lb.league_id
      AND tsp.total_points = lb.max_points
)
SELECT
    ch.season,
    tm.team_long_name    AS team_name,
    lg.name              AS league_name,
    ct.name              AS country_name,
    ch.total_points
FROM champions        AS ch
JOIN Team             AS tm ON ch.team_api_id = tm.team_api_id
JOIN League           AS lg ON ch.league_id   = lg.id
JOIN Country          AS ct ON lg.country_id  = ct.id
ORDER BY 
    ch.season,
    country_name,
    league_name,
    team_name;