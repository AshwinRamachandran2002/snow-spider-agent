WITH team_points AS (
    /* total constructor (team) points in each season */
    SELECT  ra.year,
            re.constructor_id,
            SUM(re.points) AS team_points
    FROM    results   re
    JOIN    races     ra ON ra.race_id = re.race_id
    GROUP BY ra.year,
             re.constructor_id
),
driver_points AS (
    /* points for every driver‑constructor pairing in each season */
    SELECT  ra.year,
            re.constructor_id,
            re.driver_id,
            SUM(re.points) AS driver_points
    FROM    results   re
    JOIN    races     ra ON ra.race_id = re.race_id
    GROUP BY ra.year,
             re.constructor_id,
             re.driver_id
),
best_driver AS (
    /* best (highest‑scoring) driver for every constructor in each season */
    SELECT  year,
            constructor_id,
            MAX(driver_points) AS best_driver_points
    FROM    driver_points
    GROUP BY year,
             constructor_id
),
combined AS (
    /* add team points and best‑driver points */
    SELECT  tp.year,
            tp.constructor_id,
            tp.team_points + bd.best_driver_points AS combined_points
    FROM    team_points  tp
    JOIN    best_driver  bd
           ON bd.year = tp.year
          AND bd.constructor_id = tp.constructor_id
)
SELECT      co.name      AS constructor,
            c.year,
            ROUND(c.combined_points,4) AS combined_points
FROM        combined      c
JOIN        constructors  co ON co.constructor_id = c.constructor_id
ORDER BY    c.combined_points DESC,
            co.name,
            c.year
LIMIT 3;