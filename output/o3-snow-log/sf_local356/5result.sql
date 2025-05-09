WITH lap_positions_filtered AS (   -- keep only race–lap position records
    SELECT
        lp."race_id",
        lp."driver_id",
        lp."lap",
        lp."position"
    FROM F1.F1."LAP_POSITIONS" lp
    WHERE lp."lap_type" = 'Race'
),

driver_lap_deltas AS (            -- position on current lap vs. previous lap
    SELECT
        lpf.*,
        LAG(lpf."position") OVER (PARTITION BY lpf."race_id", lpf."driver_id"
                                  ORDER BY lpf."lap")                    AS "prev_position"
    FROM lap_positions_filtered lpf
),

driver_lap_changes AS (           -- convert to signed “delta” (+ = gained places)
    SELECT
        dld."race_id",
        dld."driver_id",
        dld."lap",
        (COALESCE(dld."prev_position", dld."position") - dld."position") AS "delta"
    FROM driver_lap_deltas dld
    WHERE dld."lap" > 1                      -- ignore first-lap (start) movements
),

-- laps on which a given driver pitted
pit_flags AS (
    SELECT DISTINCT
        ps."race_id",
        ps."driver_id",
        ps."lap"
    FROM F1.F1."PIT_STOPS" ps
),

-- laps on which a given driver retired
retire_flags AS (
    SELECT DISTINCT
        rt."race_id",
        rt."driver_id",
        rt."lap"
    FROM F1.F1."RETIREMENTS" rt
),

changes_cleaned AS (               -- discard laps influenced by pits or retirements
    SELECT
        dlc.*
    FROM driver_lap_changes dlc

    LEFT JOIN pit_flags    p0 ON p0."race_id" = dlc."race_id"
                              AND p0."driver_id" = dlc."driver_id"
                              AND p0."lap" = dlc."lap"
    LEFT JOIN pit_flags    p1 ON p1."race_id" = dlc."race_id"
                              AND p1."driver_id" = dlc."driver_id"
                              AND p1."lap" = dlc."lap" - 1
    LEFT JOIN retire_flags r0 ON r0."race_id" = dlc."race_id"
                              AND r0."driver_id" = dlc."driver_id"
                              AND r0."lap" = dlc."lap"
    LEFT JOIN retire_flags r1 ON r1."race_id" = dlc."race_id"
                              AND r1."driver_id" = dlc."driver_id"
                              AND r1."lap" = dlc."lap" - 1
    WHERE p0."lap" IS NULL       -- exclude if driver pitted on either lap
      AND p1."lap" IS NULL
      AND r0."lap" IS NULL       -- exclude if driver retired on either lap
      AND r1."lap" IS NULL
      AND dlc."delta" <> 0       -- keep only genuine position changes
),

overtake_totals AS (              -- sum gains vs. losses for every driver
    SELECT
        "driver_id",
        SUM(CASE WHEN "delta" > 0 THEN  "delta"           ELSE 0 END) AS "overtakes_made",
        SUM(CASE WHEN "delta" < 0 THEN - "delta"           ELSE 0 END) AS "times_overtaken"
    FROM changes_cleaned
    GROUP BY "driver_id"
),

underwater_drivers AS (           -- drivers overtaken more often than they overtake
    SELECT "driver_id"
    FROM   overtake_totals
    WHERE  "times_overtaken" > "overtakes_made"
)

SELECT
    d."full_name"
FROM underwater_drivers u
JOIN F1.F1."DRIVERS" d
  ON d."driver_id" = u."driver_id"
ORDER BY d."full_name";