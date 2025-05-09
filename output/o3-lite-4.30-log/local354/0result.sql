WITH driver_season AS (
    SELECT
        res.driver_id,
        r.year,
        MIN(r.round) AS first_round,
        MAX(r.round) AS last_round,
        COUNT(DISTINCT r.round) AS rounds_entered
    FROM results res
    JOIN races r ON r.race_id = res.race_id
    WHERE r.year BETWEEN 1950 AND 1959
    GROUP BY res.driver_id, r.year
    HAVING rounds_entered >= 2
),
first_const AS (
    SELECT
        ds.driver_id,
        ds.year,
        res.constructor_id
    FROM driver_season ds
    JOIN races r ON r.year = ds.year AND r.round = ds.first_round
    JOIN results res ON res.race_id = r.race_id
                   AND res.driver_id = ds.driver_id
),
last_const AS (
    SELECT
        ds.driver_id,
        ds.year,
        res.constructor_id
    FROM driver_season ds
    JOIN races r ON r.year = ds.year AND r.round = ds.last_round
    JOIN results res ON res.race_id = r.race_id
                   AND res.driver_id = ds.driver_id
),
valid_pairs AS (
    SELECT
        fc.driver_id
    FROM first_const fc
    JOIN last_const lc
      ON lc.driver_id      = fc.driver_id
     AND lc.year           = fc.year
     AND lc.constructor_id = fc.constructor_id
)
SELECT DISTINCT
       dr.forename || ' ' || dr.surname AS driver
FROM valid_pairs vp
JOIN drivers dr ON dr.driver_id = vp.driver_id
ORDER BY driver;