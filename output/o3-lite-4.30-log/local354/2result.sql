WITH driver_year_results AS (
    SELECT 
        r.driver_id,
        ra.year,
        ra.round,
        r.constructor_id
    FROM results r
    JOIN races ra ON ra.race_id = r.race_id
    WHERE ra.year BETWEEN 1950 AND 1959
),
first_last AS (
    SELECT
        driver_id,
        year,
        MIN(round)  AS first_round,
        MAX(round)  AS last_round,
        COUNT(DISTINCT round) AS rounds_entered
    FROM driver_year_results
    GROUP BY driver_id, year
    HAVING rounds_entered >= 2
),
first_constructor AS (
    SELECT 
        fl.driver_id,
        fl.year,
        dyr.constructor_id AS constructor_id
    FROM first_last fl
    JOIN driver_year_results dyr
      ON  dyr.driver_id = fl.driver_id 
      AND dyr.year      = fl.year 
      AND dyr.round     = fl.first_round
),
last_constructor AS (
    SELECT 
        fl.driver_id,
        fl.year,
        dyr.constructor_id AS constructor_id
    FROM first_last fl
    JOIN driver_year_results dyr
      ON  dyr.driver_id = fl.driver_id 
      AND dyr.year      = fl.year 
      AND dyr.round     = fl.last_round
),
qualified AS (
    SELECT DISTINCT fc.driver_id
    FROM first_constructor fc
    JOIN last_constructor  lc
      ON  fc.driver_id      = lc.driver_id
      AND fc.year           = lc.year
      AND fc.constructor_id = lc.constructor_id
)
SELECT DISTINCT 
    d.forename || ' ' || d.surname AS driver
FROM qualified q
JOIN drivers  d ON d.driver_id = q.driver_id
ORDER BY driver;