WITH
-- laps that must be ignored because a pit-stop or a retirement happened
"EXCLUDED_LAPS" AS (
    SELECT DISTINCT "race_id", "lap"
    FROM "F1"."F1"."PIT_STOPS"
    UNION
    SELECT DISTINCT "race_id", "lap"
    FROM "F1"."F1"."RETIREMENTS"
),

-- positions per driver / lap (we will later pair each lap with the previous one)
"POS" AS (
    SELECT
        "race_id",
        "driver_id",
        "lap",
        "position"
    FROM "F1"."F1"."LAP_POSITIONS"
),

-- lap-to-lap deltas (current lap vs previous lap) after applying all exclusions
"DELTAS" AS (
    SELECT
        cur."driver_id",
        cur."race_id",
        cur."lap",
        cur."position"              AS "pos_curr",
        prev."position"             AS "pos_prev",
        cur."position" - prev."position" AS "delta"
    FROM "POS"  cur
    JOIN "POS"  prev
          ON  cur."driver_id" = prev."driver_id"
          AND cur."race_id"   = prev."race_id"
          AND cur."lap"       = prev."lap" + 1      -- previous lap
    -- exclude first-lap (start) movements
    WHERE cur."lap" > 1
      -- exclude any pair where either lap is in the excluded list
      AND NOT EXISTS (
              SELECT 1
              FROM "EXCLUDED_LAPS" ex
              WHERE ex."race_id" = cur."race_id"
                AND ex."lap" IN (cur."lap", prev."lap")
          )
),

-- count on-track overtakes made and suffered
"STATS" AS (
    SELECT
        "driver_id",
        SUM(CASE WHEN "delta" < 0 THEN 1 ELSE 0 END) AS "overtakes_made",
        SUM(CASE WHEN "delta" > 0 THEN 1 ELSE 0 END) AS "overtaken"
    FROM "DELTAS"
    GROUP BY "driver_id"
)

-- final list of drivers who were overtaken more often than they overtook others
SELECT
    d."full_name"
FROM "STATS"   s
JOIN "F1"."F1"."DRIVERS" d
     ON d."driver_id" = s."driver_id"
WHERE s."overtaken" > s."overtakes_made"
ORDER BY d."full_name";