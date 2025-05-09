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
driver_year_ranked AS (
    SELECT
        driver_id,
        year,
        constructor_id,
        round,
        ROW_NUMBER() OVER (PARTITION BY driver_id, year ORDER BY round)      AS rn_first,
        ROW_NUMBER() OVER (PARTITION BY driver_id, year ORDER BY round DESC) AS rn_last,
        COUNT(*)   OVER (PARTITION BY driver_id, year)                       AS rounds_cnt
    FROM driver_year_results
),
driver_year_summary AS (
    SELECT
        driver_id,
        year,
        MAX(CASE WHEN rn_first = 1 THEN constructor_id END) AS first_constructor_id,
        MAX(CASE WHEN rn_last  = 1 THEN constructor_id END) AS last_constructor_id,
        MAX(rounds_cnt)                                     AS rounds_cnt
    FROM driver_year_ranked
    GROUP BY driver_id, year
    HAVING rounds_cnt >= 2
       AND first_constructor_id = last_constructor_id
)
SELECT DISTINCT
       d.forename || ' ' || d.surname AS driver_name
FROM driver_year_summary dys
JOIN drivers d ON d.driver_id = dys.driver_id
ORDER BY driver_name;