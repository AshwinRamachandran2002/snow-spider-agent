WITH "GRID_START" AS (           -- grid positions used as lap-0 reference
    SELECT  "race_id",
            "driver_id",
            "grid"      AS "position"
    FROM    F1.F1."RESULTS"
    WHERE   "grid" IS NOT NULL
),  

"LAP_DATA" AS (                  -- combine lap-0 grid + first five race laps
    SELECT  "race_id",
            0           AS "lap",
            "driver_id",
            "position"
    FROM    "GRID_START"
    
    UNION ALL
    
    SELECT  "race_id",
            "lap",
            "driver_id",
            "position"
    FROM    F1.F1."LAP_POSITIONS"
    WHERE   "lap_type" = 'Race'
      AND   "lap"      <= 5
),  

"POS_DELTA" AS (                 -- position change per driver per lap
    SELECT  "race_id",
            "driver_id",
            "lap",
            "position",
            LAG("position") OVER (PARTITION BY "race_id","driver_id" ORDER BY "lap") AS "prev_position"
    FROM    "LAP_DATA"
),  

"OVERTAKES_RAW" AS (             -- only positive gains (overtakes) in laps 1-5
    SELECT  "race_id",
            "lap",
            "driver_id",
            ("prev_position" - "position") AS "positions_gained"
    FROM    "POS_DELTA"
    WHERE   "lap" BETWEEN 1 AND 5
      AND   "prev_position" IS NOT NULL
      AND   "prev_position" > "position"
),  

"CLASSIFIED" AS (                -- apply R / P / S / T categories
    SELECT  o."race_id",
            o."lap",
            CASE
                WHEN EXISTS (SELECT 1
                             FROM   F1.F1."RETIREMENTS" r
                             WHERE  r."race_id" = o."race_id"
                               AND  r."lap"     = o."lap")                       THEN 'R'      -- Retirement
                WHEN EXISTS (SELECT 1
                             FROM   F1.F1."PIT_STOPS" p
                             WHERE  p."race_id" = o."race_id"
                               AND  p."lap" IN (o."lap", o."lap" - 1))           THEN 'P'      -- Pit-related
                WHEN o."lap" = 1                                                 THEN 'S'      -- Start
                ELSE 'T'                                                                   -- Track
            END                           AS "category",
            o."positions_gained"
    FROM    "OVERTAKES_RAW" o
),  

"SUMMARY" AS (                   -- total overtakes per category
    SELECT  "category",
            SUM("positions_gained") AS "overtakes"
    FROM    "CLASSIFIED"
    GROUP BY "category"
)

SELECT  "category",
        "overtakes"
FROM    "SUMMARY"
ORDER BY "category";