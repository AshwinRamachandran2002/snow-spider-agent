WITH
-- 1) All laps during the race (one row per driver-lap) together with the
--    position on the previous lap for the same driver
"LAP_DELTAS" AS (
    SELECT
        lp."race_id",
        lp."driver_id",
        lp."lap",
        lp."position",
        LAG(lp."position") OVER (
            PARTITION BY lp."race_id", lp."driver_id"
            ORDER BY lp."lap"
        ) AS "prev_position"
    FROM F1.F1."LAP_POSITIONS" lp
    WHERE lp."lap_type" = 'Race'
),

-- 2) Laps that must be ignored because any car pitted or retired
"EXCLUDED_LAPS" AS (
    SELECT DISTINCT ps."race_id", ps."lap"
    FROM F1.F1."PIT_STOPS" ps
    UNION
    SELECT DISTINCT rt."race_id", rt."lap"
    FROM F1.F1."RETIREMENTS" rt
),

-- 3) For each driver, count overtakes (position improves) and
--    times being overtaken (position worsens), ignoring:
--      • first-lap changes,
--      • laps where any pit-stop or retirement occurred
"DRIVER_OVERTAKE_COUNTS" AS (
    SELECT
        ld."driver_id",
        SUM(
            CASE
                WHEN ld."prev_position" IS NOT NULL
                     AND ld."position" < ld."prev_position" THEN 1
                ELSE 0
            END
        )               AS "overtakes",
        SUM(
            CASE
                WHEN ld."prev_position" IS NOT NULL
                     AND ld."position" > ld."prev_position" THEN 1
                ELSE 0
            END
        )               AS "times_overtaken"
    FROM "LAP_DELTAS"  ld
    LEFT JOIN "EXCLUDED_LAPS" el
           ON  el."race_id" = ld."race_id"
           AND el."lap"      = ld."lap"
    WHERE ld."lap" > 1               -- exclude start movements
      AND el."race_id" IS NULL       -- exclude laps with pit-stops / retirements
    GROUP BY ld."driver_id"
)

-- 4) Return the full names of the drivers who were overtaken
--    more times than they overtook others
SELECT
    d."full_name"
FROM "DRIVER_OVERTAKE_COUNTS" doc
JOIN F1.F1."DRIVERS" d
  ON d."driver_id" = doc."driver_id"
WHERE doc."times_overtaken" > doc."overtakes"
ORDER BY d."full_name";