WITH driver_season_races AS (
    SELECT 
        res.driver_id,
        ra.year,
        ra.round,
        res.constructor_id
    FROM results AS res
    JOIN races   AS ra ON ra.race_id = res.race_id
    WHERE ra.year BETWEEN 1950 AND 1959
),
season_stats AS (
    SELECT
        driver_id,
        year,
        MIN(round) AS first_round,
        MAX(round) AS last_round,
        COUNT(DISTINCT round) AS race_count
    FROM driver_season_races
    GROUP BY driver_id, year
),
first_last_constructors AS (
    SELECT
        ss.driver_id,
        ss.year,
        ss.race_count,
        (
            SELECT constructor_id
            FROM driver_season_races AS dsr
            WHERE dsr.driver_id = ss.driver_id
              AND dsr.year = ss.year
              AND dsr.round = ss.first_round
            LIMIT 1
        ) AS first_constructor_id,
        (
            SELECT constructor_id
            FROM driver_season_races AS dsr
            WHERE dsr.driver_id = ss.driver_id
              AND dsr.year = ss.year
              AND dsr.round = ss.last_round
            LIMIT 1
        ) AS last_constructor_id
    FROM season_stats AS ss
),
qualified_drivers AS (
    SELECT DISTINCT driver_id
    FROM first_last_constructors
    WHERE race_count >= 2
      AND first_constructor_id = last_constructor_id
)

SELECT DISTINCT d.full_name AS driver_name
FROM qualified_drivers q
JOIN drivers_ext d ON d.driver_id = q.driver_id
ORDER BY driver_name;