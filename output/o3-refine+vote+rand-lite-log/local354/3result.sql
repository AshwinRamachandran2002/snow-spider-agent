WITH per_race AS (
    SELECT 
        r."driver_id",
        ra."year",
        ra."round",
        r."constructor_id"
    FROM "results" r
    JOIN "races"   ra ON ra."race_id" = r."race_id"
    WHERE ra."year" BETWEEN 1950 AND 1959
),
first_last AS (          -- first/last round and race count per driver‑season
    SELECT
        driver_id,
        year,
        MIN(round) AS first_round,
        MAX(round) AS last_round,
        COUNT(DISTINCT round) AS race_cnt
    FROM per_race
    GROUP BY driver_id, year
    HAVING race_cnt >= 2              -- at least two different rounds
),
first_con AS (           -- constructor in the first race of the season
    SELECT
        fl.driver_id,
        fl.year,
        MIN(pr.constructor_id) AS first_constructor
    FROM first_last fl
    JOIN per_race pr
         ON  pr.driver_id = fl.driver_id
         AND pr.year      = fl.year
         AND pr.round     = fl.first_round
    GROUP BY fl.driver_id, fl.year
),
last_con AS (            -- constructor in the last race of the season
    SELECT
        fl.driver_id,
        fl.year,
        MIN(pr.constructor_id) AS last_constructor
    FROM first_last fl
    JOIN per_race pr
         ON  pr.driver_id = fl.driver_id
         AND pr.year      = fl.year
         AND pr.round     = fl.last_round
    GROUP BY fl.driver_id, fl.year
),
qualified_drivers AS (   -- seasons where first & last constructor match
    SELECT DISTINCT fc.driver_id
    FROM first_con fc
    JOIN last_con  lc
         ON  lc.driver_id = fc.driver_id
         AND lc.year      = fc.year
    WHERE fc.first_constructor = lc.last_constructor
)
SELECT DISTINCT
       d.driver_id,
       d.forename || ' ' || d.surname AS driver_name
FROM qualified_drivers qd
JOIN drivers d ON d.driver_id = qd.driver_id
ORDER BY driver_name;