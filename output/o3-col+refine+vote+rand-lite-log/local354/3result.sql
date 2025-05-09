WITH driver_races AS (
    -- every start a driver made in the 1950s
    SELECT
        ra.year,
        r.driver_id,
        ra.round,
        r.constructor_id,
        ROW_NUMBER() OVER (PARTITION BY ra.year, r.driver_id ORDER BY ra.round)        AS rn_first,
        ROW_NUMBER() OVER (PARTITION BY ra.year, r.driver_id ORDER BY ra.round DESC)   AS rn_last
    FROM   results  r
    JOIN   races    ra ON ra.race_id = r.race_id
    WHERE  ra.year BETWEEN 1950 AND 1959
),
season_checks AS (
    -- per driver-season: rounds entered + constructor in first & last start
    SELECT
        year,
        driver_id,
        COUNT(DISTINCT round)                                            AS rounds_entered,
        MAX(CASE WHEN rn_first = 1 THEN constructor_id END)              AS first_constructor,
        MAX(CASE WHEN rn_last  = 1 THEN constructor_id END)              AS last_constructor
    FROM   driver_races
    GROUP  BY year, driver_id
    HAVING rounds_entered >= 2                     -- at least two distinct rounds
       AND first_constructor = last_constructor    -- same constructor in first & last race
)
SELECT DISTINCT
       d.forename || ' ' || d.surname AS driver_name
FROM   season_checks sc
JOIN   drivers       d ON d.driver_id = sc.driver_id
ORDER  BY driver_name;