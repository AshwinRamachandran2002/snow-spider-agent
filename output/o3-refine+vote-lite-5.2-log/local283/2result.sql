/*  Champion of every league‑season
    – 3 pts for win, 1 for draw, 0 for loss                                    */

WITH points AS (
    /* HOME side points */
    SELECT  m.season,
            l.name          AS league_name,
            c.name          AS country_name,
            m.home_team_api_id  AS team_api_id,
            CASE
                WHEN m.home_team_goal > m.away_team_goal THEN 3
                WHEN m.home_team_goal = m.away_team_goal THEN 1
                ELSE 0
            END            AS pts
    FROM "Match"  m
    JOIN "League"  l ON l.id          = m.league_id
    JOIN "Country" c ON c.id          = l.country_id

    UNION ALL

    /* AWAY side points */
    SELECT  m.season,
            l.name,
            c.name,
            m.away_team_api_id,
            CASE
                WHEN m.away_team_goal > m.home_team_goal THEN 3
                WHEN m.away_team_goal = m.home_team_goal THEN 1
                ELSE 0
            END
    FROM "Match"  m
    JOIN "League"  l ON l.id          = m.league_id
    JOIN "Country" c ON c.id          = l.country_id
),

team_season_points AS (
    SELECT  season,
            league_name,
            country_name,
            team_api_id,
            SUM(pts) AS total_points
    FROM points
    GROUP BY season, league_name, country_name, team_api_id
)

SELECT   tsp.season,
         t.team_long_name AS champion_team,
         tsp.league_name,
         tsp.country_name,
         tsp.total_points
FROM     team_season_points  tsp
JOIN     "Team"             t   ON t.team_api_id = tsp.team_api_id
WHERE    tsp.total_points = (
            SELECT MAX(tsp2.total_points)
            FROM   team_season_points tsp2
            WHERE  tsp2.season        = tsp.season
              AND  tsp2.league_name   = tsp.league_name
              AND  tsp2.country_name  = tsp.country_name
         )
ORDER BY tsp.country_name,
         tsp.league_name,
         tsp.season;