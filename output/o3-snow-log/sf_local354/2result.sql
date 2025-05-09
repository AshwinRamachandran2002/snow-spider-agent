WITH drives_50s AS (
    SELECT 
        "year",
        "driver_id",
        "constructor_id",
        "first_round",
        "last_round",
        "drive_id"
    FROM F1.F1.DRIVES
    WHERE "year" BETWEEN 1950 AND 1959
),

-- constructor used in the very first round a driver contested that season
first_drive AS (
    SELECT 
        "year",
        "driver_id",
        "constructor_id"  AS "constructor_first",
        "first_round"
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY "year","driver_id" 
                                  ORDER BY "first_round" ASC, "drive_id" ASC) AS rn
        FROM drives_50s
    ) fd
    WHERE rn = 1
),

-- constructor used in the very last round a driver contested that season
last_drive AS (
    SELECT 
        "year",
        "driver_id",
        "constructor_id"  AS "constructor_last",
        "last_round"
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY "year","driver_id" 
                                  ORDER BY "last_round" DESC, "drive_id" DESC) AS rn
        FROM drives_50s
    ) ld
    WHERE rn = 1
),

season_summary AS (
    SELECT
        fd."year",
        fd."driver_id",
        fd."constructor_first",
        fd."first_round",
        ld."constructor_last",
        ld."last_round"
    FROM first_drive fd
    JOIN last_drive  ld
      ON fd."year" = ld."year"
     AND fd."driver_id" = ld."driver_id"
)

SELECT DISTINCT
       d."full_name" AS "driver_name"
FROM season_summary ss
JOIN F1.F1.DRIVERS d
  ON ss."driver_id" = d."driver_id"
WHERE ss."constructor_first" = ss."constructor_last"    -- same constructor in first and last race
  AND ss."last_round" > ss."first_round"                -- at least two different rounds contested
ORDER BY "driver_name";