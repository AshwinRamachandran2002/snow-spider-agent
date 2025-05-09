WITH overtake_events AS (
    /* laps where a driver was NOT directly behind the same car on the previous lap
       but IS directly behind one now – only for races that have pit‑stop data      */
    SELECT
        lp_now."race_id",
        lp_now."lap",
        lp_now."driver_id"               AS "follower",
        lp_now_ahead."driver_id"         AS "leader"
    FROM   "lap_positions" lp_now
    JOIN   "races_ext"     re
           ON re."race_id" = lp_now."race_id"
          AND re."is_pit_data_available" = 1
    JOIN   "lap_positions" lp_now_ahead
           ON lp_now_ahead."race_id"  = lp_now."race_id"
          AND lp_now_ahead."lap"      = lp_now."lap"
          AND lp_now_ahead."position" = lp_now."position" - 1   -- car directly ahead
    LEFT  JOIN "lap_positions" lp_prev
           ON lp_prev."race_id"  = lp_now."race_id"
          AND lp_prev."lap"      = lp_now."lap" - 1             -- previous lap
          AND lp_prev."driver_id"= lp_now."driver_id"
    WHERE  lp_prev."position" IS NULL          -- was NOT behind same car last lap
       OR  lp_prev."position" - 1 <> lp_now."position"
),
typed_events AS (
    /* classify each “newly‑behind” event */
    SELECT
        oe."race_id",
        oe."lap",
        CASE
             WHEN ps_in."driver_id"  IS NOT NULL THEN 'Leader entered pits'
             WHEN ps_out."driver_id" IS NOT NULL THEN 'Follower exited pits'
             WHEN rt."driver_id"     IS NOT NULL THEN 'Leader retirement'
             WHEN oe."lap" = 1                      THEN 'Race start shuffle'
             ELSE 'On‑track overtake'
        END AS "overtake_type"
    FROM   overtake_events oe
    LEFT  JOIN "pit_stops" ps_in
           ON ps_in."race_id"  = oe."race_id"
          AND ps_in."driver_id"= oe."leader"
          AND ps_in."lap"      = oe."lap"          -- leader dives into pits
    LEFT  JOIN "pit_stops" ps_out
           ON ps_out."race_id"  = oe."race_id"
          AND ps_out."driver_id"= oe."follower"
          AND ps_out."lap"      = oe."lap" - 1     -- follower exits pits
    LEFT  JOIN "retirements" rt
           ON rt."race_id"      = oe."race_id"
          AND rt."driver_id"    = oe."leader"
          AND rt."lap"          = oe."lap"         -- leader retires this lap
)
SELECT
    "overtake_type",
    COUNT(*) AS "num_occurrences"
FROM   typed_events
GROUP  BY "overtake_type"
ORDER BY "num_occurrences" DESC;