WITH eligible_laps AS (
    SELECT
        lp."race_id",
        lp."driver_id",
        lp."lap",
        lp."position",
        lp."lap_type",
        LAG(lp."position") OVER (
            PARTITION BY lp."race_id", lp."driver_id"
            ORDER BY lp."lap"
        ) AS "prev_position",
        LAG(lp."lap_type") OVER (
            PARTITION BY lp."race_id", lp."driver_id"
            ORDER BY lp."lap"
        ) AS "prev_lap_type"
    FROM   "lap_positions" lp
    JOIN   "races_ext"     re ON re."race_id" = lp."race_id"
    WHERE  re."is_pit_data_available" = 1
),
position_losses AS (
    SELECT
        ("position" - "prev_position") AS "overtakes",
        CASE
            WHEN "prev_lap_type" LIKE '%Starting%'    THEN 'Race start'
            WHEN "prev_lap_type" LIKE '%Pit Entry%'   THEN 'Pit entry'
            WHEN "lap_type"      LIKE '%Pit Exit%'    THEN 'Pit exit'
            WHEN "lap_type"      LIKE '%Retirement%'
              OR "prev_lap_type" LIKE '%Retirement%' THEN 'Retirement'
            ELSE                                       'On track'
        END AS "overtake_type"
    FROM   eligible_laps
    WHERE  "prev_position" IS NOT NULL
      AND  "position" > "prev_position"           -- driver was ahead last lap, behind this lap
)
SELECT
    "overtake_type",
    SUM("overtakes") AS "total_overtakes"
FROM   position_losses
GROUP  BY "overtake_type"
ORDER  BY "total_overtakes" DESC;