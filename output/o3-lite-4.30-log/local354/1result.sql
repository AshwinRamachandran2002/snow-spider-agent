WITH driver_seasons AS (
    SELECT
        r.driver_id,
        ra.year,
        COUNT(DISTINCT ra.round) AS num_rounds,
        MIN(ra.round)            AS first_round,
        MAX(ra.round)            AS last_round
    FROM results r
    JOIN races  ra ON ra.race_id = r.race_id
    WHERE ra.year BETWEEN 1950 AND 1959
    GROUP BY r.driver_id, ra.year
    HAVING num_rounds >= 2
),
first_cons AS (
    SELECT
        ds.driver_id,
        ds.year,
        MIN(r.constructor_id) AS constructor_id
    FROM driver_seasons ds
    JOIN races   ra ON ra.year = ds.year  AND ra.round = ds.first_round
    JOIN results r  ON r.race_id = ra.race_id AND r.driver_id = ds.driver_id
    GROUP BY ds.driver_id, ds.year
),
last_cons AS (
    SELECT
        ds.driver_id,
        ds.year,
        MIN(r.constructor_id) AS constructor_id
    FROM driver_seasons ds
    JOIN races   ra ON ra.year = ds.year  AND ra.round = ds.last_round
    JOIN results r  ON r.race_id = ra.race_id AND r.driver_id = ds.driver_id
    GROUP BY ds.driver_id, ds.year
),
qualified AS (
    SELECT fc.driver_id
    FROM first_cons fc
    JOIN last_cons  lc ON lc.driver_id = fc.driver_id AND lc.year = fc.year
    WHERE fc.constructor_id = lc.constructor_id
)
SELECT DISTINCT
       d.forename || ' ' || d.surname AS driver
FROM qualified q
JOIN drivers d ON d.driver_id = q.driver_id
ORDER BY driver;