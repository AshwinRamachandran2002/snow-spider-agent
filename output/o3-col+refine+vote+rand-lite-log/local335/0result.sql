WITH driver_totals AS (
    /* season-level points for every driver (since 2001) who scored > 0 */
    SELECT  ra.year,
            re.driver_id,
            SUM(re.points) AS season_points
    FROM    results  re
    JOIN    races    ra ON ra.race_id = re.race_id
    WHERE   ra.year >= 2001
    GROUP BY ra.year, re.driver_id
    HAVING  SUM(re.points) > 0
),
min_point_drivers AS (
    /* drivers whose season total equals the minimum positive total for that year */
    SELECT  year,
            driver_id
    FROM   (
        SELECT  dt.*,
                RANK() OVER (PARTITION BY year ORDER BY season_points) AS rnk
        FROM    driver_totals dt
    )
    WHERE   rnk = 1
)
SELECT  c.name  AS constructor,
        COUNT(DISTINCT ra.year) AS seasons_with_min_point_driver
FROM    min_point_drivers md
JOIN    results      re ON re.driver_id = md.driver_id
JOIN    races        ra ON ra.race_id   = re.race_id
                       AND ra.year      = md.year          -- ensure same season
JOIN    constructors c  ON c.constructor_id = re.constructor_id
GROUP   BY c.constructor_id, c.name
ORDER   BY seasons_with_min_point_driver DESC,
         constructor ASC
LIMIT 5;