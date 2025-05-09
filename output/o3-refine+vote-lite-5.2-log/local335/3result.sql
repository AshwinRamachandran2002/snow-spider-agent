WITH driver_constructor_season_points AS (
    /* points scored by every driver for each constructor in a given season (2001+) */
    SELECT  r.year,
            res.driver_id,
            res.constructor_id,
            SUM(res.points) AS constructor_points
    FROM    results        res
    JOIN    races          r   ON r.race_id = res.race_id
    WHERE   r.year >= 2001
    GROUP BY r.year, res.driver_id, res.constructor_id
),
driver_season_points AS (
    /* give every driver one constructor – the one with which he scored most points –  
       and keep only drivers who scored > 0 points in the season                */
    SELECT dcsp.year,
           dcsp.driver_id,
           dcsp.constructor_id,
           dcsp.constructor_points AS total_points
    FROM   driver_constructor_season_points dcsp
    JOIN  (
            SELECT year,
                   driver_id,
                   MAX(constructor_points) AS max_points
            FROM   driver_constructor_season_points
            GROUP BY year, driver_id
           ) mx 
           ON  mx.year       = dcsp.year
           AND mx.driver_id  = dcsp.driver_id
           AND mx.max_points = dcsp.constructor_points
    WHERE  dcsp.constructor_points > 0
),
season_min_points AS (
    /* the fewest points scored by any point‑scoring driver in each season */
    SELECT year,
           MIN(total_points) AS min_points
    FROM   driver_season_points
    GROUP BY year
),
constructors_with_least_driver AS (
    /* constructors that had at least one such lowest‑scoring driver in a season */
    SELECT DISTINCT
           dsp.year,
           dsp.constructor_id
    FROM   driver_season_points dsp
    JOIN   season_min_points   smp
           ON  smp.year = dsp.year
           AND smp.min_points = dsp.total_points
)
SELECT  c.name,
        COUNT(*) AS seasons_with_least_scoring_driver
FROM    constructors_with_least_driver cld
JOIN    constructors               c ON c.constructor_id = cld.constructor_id
GROUP BY c.constructor_id, c.name
ORDER BY seasons_with_least_scoring_driver DESC,
         c.name
LIMIT 5;