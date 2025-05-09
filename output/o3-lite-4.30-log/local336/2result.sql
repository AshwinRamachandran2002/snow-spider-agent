WITH pos AS (
    SELECT
        "race_id",
        "driver_id",
        "lap",
        "position",
        LAG("position") OVER (PARTITION BY "driver_id" ORDER BY "lap") AS "prev_pos"
    FROM "lap_positions"
    WHERE "race_id" = 1
      AND "lap_type" = 'Race'
      AND "lap" BETWEEN 0 AND 5
),
moves AS (                       -- position changes between consecutive laps
    SELECT
        "race_id",
        "driver_id",
        "lap",
        ("prev_pos" - "position") AS delta              -- positive = places gained
    FROM pos
    WHERE "lap" BETWEEN 1 AND 5
      AND "prev_pos" IS NOT NULL
      AND "prev_pos" <> "position"
),
gains AS (                       -- keep only genuine overtakes (positive gains)
    SELECT
        "race_id",
        "driver_id",
        "lap",
        delta
    FROM moves
    WHERE delta > 0
),
tagged AS (                      -- categorise each gain
    SELECT
        CASE
            WHEN EXISTS (SELECT 1
                         FROM "retirements" r
                         WHERE r."race_id" = g."race_id"
                           AND r."lap"     = g."lap"
                           AND r."driver_id" <> g."driver_id") THEN 'retirement'
            WHEN EXISTS (SELECT 1
                         FROM "pit_stops" p
                         WHERE p."race_id" = g."race_id"
                           AND p."lap"     = g."lap")          THEN 'pit_stop'
            WHEN g."lap" = 1                                     THEN 'start_related'
            ELSE 'on_track'
        END AS overtake_type,
        g.delta
    FROM gains g
)
SELECT
    overtake_type,
    SUM(delta) AS overtake_count
FROM tagged
GROUP BY overtake_type
ORDER BY overtake_type;