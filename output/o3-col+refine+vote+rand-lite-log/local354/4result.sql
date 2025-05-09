WITH driver_season AS (
    /* seasons in the 1950-1959 decade where the driver started ≥2 different rounds */
    SELECT 
        r.year,
        res.driver_id,
        MIN(r.round) AS first_round,
        MAX(r.round) AS last_round,
        COUNT(DISTINCT r.round) AS rounds_entered
    FROM results   AS res
    JOIN races     AS r  ON r.race_id = res.race_id
    WHERE r.year BETWEEN 1950 AND 1959
    GROUP BY r.year, res.driver_id
    HAVING rounds_entered >= 2
),
first_constructor AS (
    /* constructor used in the driver’s first race of the season */
    SELECT 
        ds.year,
        ds.driver_id,
        res.constructor_id AS first_constructor_id
    FROM driver_season AS ds
    JOIN results       AS res ON res.driver_id = ds.driver_id
    JOIN races         AS r   ON r.race_id = res.race_id
                              AND r.year   = ds.year
                              AND r.round  = ds.first_round
),
last_constructor AS (
    /* constructor used in the driver’s last race of the season */
    SELECT 
        ds.year,
        ds.driver_id,
        res.constructor_id AS last_constructor_id
    FROM driver_season AS ds
    JOIN results       AS res ON res.driver_id = ds.driver_id
    JOIN races         AS r   ON r.race_id = res.race_id
                              AND r.year   = ds.year
                              AND r.round  = ds.last_round
),
qualified AS (
    /* keep driver-seasons where first and last constructor match */
    SELECT 
        fc.year,
        fc.driver_id
    FROM first_constructor AS fc
    JOIN last_constructor  AS lc
      ON lc.year = fc.year
     AND lc.driver_id = fc.driver_id
    WHERE fc.first_constructor_id = lc.last_constructor_id
)
SELECT DISTINCT
       d.forename || ' ' || d.surname AS driver_name
FROM qualified  AS q
JOIN drivers    AS d ON d.driver_id = q.driver_id
ORDER BY driver_name;