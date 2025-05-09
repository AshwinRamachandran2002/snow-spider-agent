WITH driver_season AS (        -- every driver-season in the 1950s
    SELECT
        res.driver_id,
        ra.year,
        MIN(ra.round)               AS first_round,
        MAX(ra.round)               AS last_round,
        COUNT(DISTINCT ra.round)    AS race_count
    FROM results   res
    JOIN races     ra ON ra.race_id = res.race_id
    WHERE ra.year BETWEEN 1950 AND 1959
    GROUP BY res.driver_id, ra.year
),
first_last AS (                 -- constructor in first & last race of that season
    SELECT
        ds.driver_id,
        ds.year,
        ds.race_count,
        (SELECT r1.constructor_id
         FROM   results r1
         JOIN   races   ra1 ON ra1.race_id = r1.race_id
         WHERE  r1.driver_id = ds.driver_id
           AND  ra1.year     = ds.year
           AND  ra1.round    = ds.first_round
         LIMIT 1) AS first_constructor,
        (SELECT r2.constructor_id
         FROM   results r2
         JOIN   races   ra2 ON ra2.race_id = r2.race_id
         WHERE  r2.driver_id = ds.driver_id
           AND  ra2.year     = ds.year
           AND  ra2.round    = ds.last_round
         LIMIT 1) AS last_constructor
    FROM driver_season ds
)
SELECT DISTINCT
       d.forename || ' ' || d.surname AS driver_name,
       fl.year
FROM   first_last fl
JOIN   drivers d ON d.driver_id = fl.driver_id
WHERE  fl.race_count        >= 2          -- at least two different rounds
  AND  fl.first_constructor = fl.last_constructor
ORDER  BY fl.year, driver_name;