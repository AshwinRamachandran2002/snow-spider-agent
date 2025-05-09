/*----------------------------------------------------------
  Overtakes in the first five laps, classified as
   R – caused by retirements (lap ≤ 5)
   P – related to pit-stops   (lap ≤ 5)
   S – start-lap overtakes    (grid → lap-1, lap = 1)
   T – normal on-track passes (everything else)

  Output: category | overtake_count
----------------------------------------------------------*/
WITH
/* grid (starting) positions */
grid AS (
    SELECT
        q."race_id",
        q."driver_id",
        q."position"      AS "grid_pos"
    FROM F1.F1."QUALIFYING" q
),
/* positions for laps 1-5 (race laps only) */
lap_pos AS (
    SELECT
        lp."race_id",
        lp."driver_id",
        lp."lap",
        lp."position"
    FROM F1.F1."LAP_POSITIONS" lp
    WHERE lp."lap_type" = 'Race'
      AND lp."lap"      <= 5
),
/* current lap position vs. previous position
   (grid for lap-1, otherwise previous lap)            */
pos_with_prev AS (
    SELECT
        lp."race_id",
        lp."driver_id",
        lp."lap",
        lp."position",
        CASE
            WHEN lp."lap" = 1
                 THEN g."grid_pos"
            ELSE LAG(lp."position")
                 OVER (PARTITION BY lp."race_id", lp."driver_id"
                       ORDER BY lp."lap")
        END                       AS "prev_position"
    FROM lap_pos lp
    LEFT JOIN grid g
           ON g."race_id"  = lp."race_id"
          AND g."driver_id"= lp."driver_id"
),
/* every positive position gain represents that many
   single overtakes                                         */
overtake_events AS (
    SELECT
        "race_id",
        "driver_id",
        "lap",
        ("prev_position" - "position")   AS "positions_gained"
    FROM pos_with_prev
    WHERE "prev_position" IS NOT NULL
      AND "position"      <  "prev_position"        -- improvement
),
/* aggregated counts --------------------------------------*/
totals AS (
    SELECT
        /* total number of overtakes in laps 1-5            */
        COALESCE(SUM("positions_gained"),0)                         AS total_ot,
        /* start-lap (lap-1) overtakes                        */
        COALESCE(SUM(CASE WHEN "lap" = 1
                          THEN "positions_gained" END),0)           AS start_ot
    FROM overtake_events
),
retirements AS (      -- drivers retiring in laps 1-5
    SELECT COUNT(*) AS ret_ot
    FROM F1.F1."RETIREMENTS"
    WHERE "lap" <= 5
),
pits AS (             -- pit-stops made in laps 1-5
    SELECT COUNT(*) AS pit_ot
    FROM F1.F1."PIT_STOPS"
    WHERE "lap" <= 5
),
/* compile the four classes --------------------------------*/
calc AS (
    SELECT
        t.total_ot,
        t.start_ot,
        p.pit_ot,
        r.ret_ot
    FROM totals      t,
         pits        p,
         retirements r
),
final AS (
    SELECT 'R' AS "category", ret_ot                            AS "overtake_count" FROM calc
    UNION ALL
    SELECT 'P',               pit_ot                            FROM calc
    UNION ALL
    SELECT 'S',               start_ot                          FROM calc
    UNION ALL
    SELECT 'T',               (total_ot - start_ot - pit_ot - ret_ot) FROM calc
)
SELECT "category", "overtake_count"
FROM   final
ORDER BY "category";