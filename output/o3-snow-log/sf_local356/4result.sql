WITH "LAP_POS" AS (          -- every driver’s position at the end of each race lap
    SELECT  "race_id",
            "driver_id",
            "lap",
            "position"
    FROM    F1.F1.LAP_POSITIONS
    WHERE   "lap_type" = 'Race'
),
"LAP_DIFFS" AS (             -- position change from one lap to the next
    SELECT  cur."race_id",
            cur."driver_id",
            cur."lap",                       -- this is the CURRENT lap
            prev."position"  AS "prev_pos",  -- position end-of previous lap
            cur."position"   AS "curr_pos",
            prev."position" - cur."position" AS "delta"   -- +ve = places gained
    FROM    "LAP_POS" cur
    JOIN    "LAP_POS" prev
           ON cur."race_id"  = prev."race_id"
          AND cur."driver_id"= prev."driver_id"
          AND cur."lap"       = prev."lap" + 1            -- consecutive laps
),
/* laps in which any pit activity or a retirement happens,
   as well as the lap immediately AFTER a pit stop (pit-exit)                       */
"PIT_LAPS"     AS (SELECT DISTINCT "race_id","lap" FROM F1.F1.PIT_STOPS),
"RETIRE_LAPS"  AS (SELECT DISTINCT "race_id","lap" FROM F1.F1.RETIREMENTS),
"EXCLUDE_LAPS" AS (
    SELECT DISTINCT "race_id","lap" FROM (
        SELECT "race_id","lap"         FROM "PIT_LAPS"
        UNION ALL
        SELECT "race_id","lap" + 1     FROM "PIT_LAPS"    -- pit-exit lap
        UNION ALL
        SELECT "race_id","lap"         FROM "RETIRE_LAPS"
    )
),
"VALID_DIFFS" AS (           -- keep only genuine on-track passes
    SELECT  d.*
    FROM    "LAP_DIFFS" d
    LEFT JOIN "EXCLUDE_LAPS" e
           ON d."race_id" = e."race_id"
          AND d."lap"     = e."lap"
    WHERE   e."lap" IS NULL          -- not a pit / retirement lap
      AND   d."delta" <> 0           -- position actually changed
),
"OVERTAKE_COUNTS" AS (       -- totals per driver
    SELECT  "driver_id",
            SUM(CASE WHEN "delta" > 0 THEN  "delta" ELSE 0 END) AS "overtakes_made",
            SUM(CASE WHEN "delta" < 0 THEN - "delta" ELSE 0 END) AS "overtakes_suffered"
    FROM    "VALID_DIFFS"
    GROUP BY "driver_id"
),
"NEGATIVE_DRIVERS" AS (      -- drivers overtaken more than they overtake
    SELECT  "driver_id"
    FROM    "OVERTAKE_COUNTS"
    WHERE   "overtakes_suffered" > "overtakes_made"
)
SELECT  d."full_name"
FROM    F1.F1.DRIVERS d
JOIN    "NEGATIVE_DRIVERS" n
      ON d."driver_id" = n."driver_id"
ORDER BY d."full_name";