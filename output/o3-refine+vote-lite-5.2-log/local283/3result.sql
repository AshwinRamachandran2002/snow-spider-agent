WITH team_points AS (        -- 1.  points of every team in every season
    SELECT  season,
            team_id,
            SUM(points)   AS total_points
    FROM   (
              /* points collected when the team plays at home */
              SELECT  season,
                      home_team_api_id        AS team_id,
                      CASE WHEN home_team_goal > away_team_goal THEN 3
                           WHEN home_team_goal = away_team_goal THEN 1
                           ELSE 0 END         AS points
              FROM    "Match"

              UNION ALL

              /* points collected when the team plays away */
              SELECT  season,
                      away_team_api_id        AS team_id,
                      CASE WHEN away_team_goal > home_team_goal THEN 3
                           WHEN away_team_goal = home_team_goal THEN 1
                           ELSE 0 END         AS points
              FROM    "Match"
           )
    GROUP BY season , team_id
),

season_max AS (               -- 2.  best points total of each season
    SELECT  season,
            MAX(total_points) AS max_points
    FROM    team_points
    GROUP BY season
),

champions AS (                -- 3.  team that reaches the best total (tie‑breaker : smallest team_id)
    SELECT  tp.season,
            tp.team_id,
            tp.total_points
    FROM    team_points  tp
            JOIN season_max sm
                 ON  sm.season = tp.season
                 AND sm.max_points = tp.total_points
    WHERE   tp.team_id = (   SELECT MIN(tp2.team_id)
                             FROM   team_points tp2
                             WHERE  tp2.season = tp.season
                             AND    tp2.total_points = tp.total_points)
)

SELECT  c.season                                           AS season,
        t.team_long_name                                   AS team_name,
        MIN(l.name)                                        AS league_name,
        MIN(co.name)                                       AS country_name,
        c.total_points                                     AS points
FROM        champions      c
JOIN        "Team"         t  ON t.team_api_id = c.team_id
JOIN        "Match"        m  ON m.season = c.season
                               AND (m.home_team_api_id = c.team_id
                                    OR m.away_team_api_id = c.team_id)
JOIN        "League"       l  ON l.id = m.league_id
JOIN        "Country"      co ON co.id = m.country_id
GROUP BY    c.season , t.team_long_name , c.total_points
ORDER BY    c.season;