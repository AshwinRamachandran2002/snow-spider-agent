WITH position_changes AS (
    /* lap‑by‑lap position deltas for the opening five laps */
    SELECT
        lp_prev."race_id",
        lp_prev."driver_id",
        lp_prev."lap" + 1                 AS "lap",
        CASE WHEN lp_prev."lap" = 0
             THEN 'start'                 /* grid‑to‑lap‑1 change   */
             ELSE 'race'                  /* ordinary lap change    */
        END                               AS "change_type",
        lp_prev."position"                AS "prev_pos",
        lp_curr."position"                AS "curr_pos",
        lp_prev."position" - lp_curr."position"  AS "delta"
    FROM   "lap_positions" lp_prev
    JOIN   "lap_positions" lp_curr
           ON  lp_curr."race_id"   = lp_prev."race_id"
           AND lp_curr."driver_id" = lp_prev."driver_id"
           AND lp_curr."lap"       = lp_prev."lap" + 1
    WHERE  lp_curr."lap" <= 5               /* limit to first 5 laps */
),
overtake_totals AS (
    SELECT
        SUM(CASE WHEN delta > 0 THEN delta ELSE 0 END)                              AS total_overtakes,
        SUM(CASE WHEN delta > 0 AND change_type = 'start' THEN delta ELSE 0 END)     AS start_overtakes
    FROM   position_changes
),
retirement_overtakes AS (
    /* one “overtake” counted for every retirement in laps 1‑5 */
    SELECT COUNT(*) AS retirement_overtakes
    FROM   "retirements"
    WHERE  "lap" IS NOT NULL
      AND  "lap" <= 5
),
pit_overtakes AS (
    /* one “overtake” counted for every pit stop in laps 1‑5 */
    SELECT COUNT(*) AS pit_overtakes
    FROM   "pit_stops"
    WHERE  "lap" <= 5
)
SELECT
        (SELECT retirement_overtakes FROM retirement_overtakes)        AS retirements,
        (SELECT pit_overtakes        FROM pit_overtakes)               AS pit_stops,
        (SELECT start_overtakes      FROM overtake_totals)             AS start_related_overtakes,
        (SELECT total_overtakes      FROM overtake_totals)
      - (SELECT retirement_overtakes FROM retirement_overtakes)
      - (SELECT pit_overtakes        FROM pit_overtakes)
      - (SELECT start_overtakes      FROM overtake_totals)             AS standard_on_track_passes;