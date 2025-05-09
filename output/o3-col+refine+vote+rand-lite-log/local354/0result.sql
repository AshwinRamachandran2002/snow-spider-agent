WITH driver_rounds AS (
    SELECT 
        r.year,
        res.driver_id,
        MIN(r.round) AS first_round,
        MAX(r.round) AS last_round,
        COUNT(DISTINCT r.round) AS rounds_entered
    FROM results AS res
    JOIN races   AS r ON r.race_id = res.race_id
    WHERE r.year BETWEEN 1950 AND 1959
    GROUP BY r.year, res.driver_id
    HAVING rounds_entered >= 2               -- at least two different rounds
),
first_constructor AS (
    SELECT 
        dr.year,
        dr.driver_id,
        res.constructor_id AS constructor_first
    FROM driver_rounds AS dr
    JOIN races      AS r   ON r.year  = dr.year  AND r.round = dr.first_round
    JOIN results    AS res ON res.race_id = r.race_id AND res.driver_id = dr.driver_id
),
last_constructor AS (
    SELECT 
        dr.year,
        dr.driver_id,
        res.constructor_id AS constructor_last
    FROM driver_rounds AS dr
    JOIN races      AS r   ON r.year  = dr.year  AND r.round = dr.last_round
    JOIN results    AS res ON res.race_id = r.race_id AND res.driver_id = dr.driver_id
)
SELECT DISTINCT 
       d.forename || ' ' || d.surname AS driver_name
FROM first_constructor  AS f
JOIN last_constructor   AS l
      ON l.year = f.year
     AND l.driver_id = f.driver_id
JOIN drivers            AS d ON d.driver_id = f.driver_id
WHERE f.constructor_first = l.constructor_last
ORDER BY driver_name;