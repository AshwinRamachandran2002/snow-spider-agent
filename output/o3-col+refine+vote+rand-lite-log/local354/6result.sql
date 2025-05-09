WITH races_1950s AS (               -- every 1950-59 race entry
    SELECT r.year,
           r.round,
           res.driver_id,
           res.constructor_id
    FROM   results   AS res
    JOIN   races     AS r  ON r.race_id = res.race_id
    WHERE  r.year BETWEEN 1950 AND 1959
),
driver_season_counts AS (           -- keep driver-seasons with ≥2 rounds
    SELECT driver_id,
           year,
           COUNT(DISTINCT round) AS race_cnt
    FROM   races_1950s
    GROUP  BY driver_id, year
    HAVING race_cnt >= 2
),
first_last AS (                     -- constructor in first vs. last round
    SELECT dsc.driver_id,
           dsc.year,
           (SELECT constructor_id          -- first round
            FROM   races_1950s
            WHERE  driver_id = dsc.driver_id
              AND  year       = dsc.year
            ORDER  BY round
            LIMIT  1)                       AS first_constructor,
           (SELECT constructor_id          -- last round
            FROM   races_1950s
            WHERE  driver_id = dsc.driver_id
              AND  year       = dsc.year
            ORDER  BY round DESC
            LIMIT  1)                       AS last_constructor
    FROM driver_season_counts AS dsc
)
SELECT DISTINCT
       d.forename || ' ' || d.surname AS driver_name
FROM   first_last  AS fl
JOIN   drivers     AS d  ON d.driver_id = fl.driver_id
WHERE  fl.first_constructor = fl.last_constructor
ORDER  BY driver_name;