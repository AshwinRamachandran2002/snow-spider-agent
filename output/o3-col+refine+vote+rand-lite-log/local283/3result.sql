WITH match_points AS (
    /* give every (team, match) the points it earned                */
    SELECT  id,
            season,
            league_id,
            home_team_api_id AS team_api_id,
            CASE
                 WHEN home_team_goal  > away_team_goal THEN 3
                 WHEN home_team_goal  = away_team_goal THEN 1
                 ELSE 0
            END               AS points
    FROM   Match
    UNION ALL
    SELECT  id,
            season,
            league_id,
            away_team_api_id AS team_api_id,
            CASE
                 WHEN away_team_goal  > home_team_goal THEN 3
                 WHEN away_team_goal  = home_team_goal THEN 1
                 ELSE 0
            END               AS points
    FROM   Match
),
season_totals AS (
    /* aggregate the points per team, per league, per season        */
    SELECT  season,
            league_id,
            team_api_id,
            SUM(points) AS total_points
    FROM    match_points
    GROUP BY season, league_id, team_api_id
),
ranked AS (
    /* rank the teams inside every (season, league) by their points */
    SELECT  season,
            league_id,
            team_api_id,
            total_points,
            RANK() OVER (PARTITION BY season, league_id
                         ORDER BY total_points DESC) AS rk
    FROM    season_totals
)
SELECT  r.season,
        c.name                 AS country,
        l.name                 AS league,
        t.team_long_name       AS champion_team,
        r.total_points
FROM    ranked   AS r
JOIN    League   AS l ON l.id          = r.league_id
JOIN    Country  AS c ON c.id          = l.country_id
JOIN    Team     AS t ON t.team_api_id = r.team_api_id
WHERE   r.rk = 1                        -- champions (incl. ties)
ORDER BY r.season,
         country,
         league,
         champion_team;