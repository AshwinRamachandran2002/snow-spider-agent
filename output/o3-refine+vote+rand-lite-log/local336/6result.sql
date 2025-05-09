WITH
-- 1. grid position (lap 0) and position at the end of lap‑1
grid_pos AS (
    SELECT race_id,
           driver_id,
           position AS grid_position
    FROM lap_positions
    WHERE lap = 0
),
lap1_pos AS (
    SELECT race_id,
           driver_id,
           position AS lap1_position
    FROM lap_positions
    WHERE lap = 1
),

/* --------------------------------------------------------------------------
   2. “Start‑related” overtakes  
      (positions gained between the grid and the end of lap‑1).  
      Every pass involves two cars, so we divide the summed position‑gains
      by 2 to obtain the number of actual overtaking moves.
-----------------------------------------------------------------------------*/
start_overtakes AS (
    SELECT  g.race_id,
            SUM(
                CASE
                    WHEN g.grid_position > l.lap1_position
                    THEN g.grid_position - l.lap1_position
                    ELSE 0
                END
            ) / 2.0 AS start_related
    FROM    grid_pos g
    JOIN    lap1_pos l
           ON l.race_id  = g.race_id
          AND l.driver_id = g.driver_id
    GROUP BY g.race_id
),

/* --------------------------------------------------------------------------
   3. Position changes from lap‑1 to lap‑5 (inclusive)
-----------------------------------------------------------------------------*/
race_laps AS (
    SELECT *
    FROM   lap_positions
    WHERE  lap BETWEEN 1 AND 5
),
lap_changes AS (
    SELECT  race_id,
            driver_id,
            lap,
            position,
            LAG(position) OVER (PARTITION BY race_id, driver_id
                                ORDER BY lap) AS prev_position
    FROM    race_laps
),
ontrack_overtakes_raw AS (
    /* raw on‑track gains (before separating pit/retirement moves)          */
    SELECT  race_id,
            SUM(
                CASE
                    WHEN prev_position IS NOT NULL AND prev_position > position
                    THEN prev_position - position
                    ELSE 0
                END
            ) / 2.0 AS raw_ontrack
    FROM    lap_changes
    GROUP BY race_id
),

/* --------------------------------------------------------------------------
   4. Early pit‑stops and retirements (laps ≤ 5)
-----------------------------------------------------------------------------*/
early_pits AS (
    SELECT race_id,
           COUNT(*) AS pit_stops
    FROM   pit_stops
    WHERE  lap <= 5
    GROUP BY race_id
),
early_rets AS (
    SELECT race_id,
           COUNT(*) AS retirements
    FROM   retirements
    WHERE  lap <= 5
    GROUP BY race_id
),

/* --------------------------------------------------------------------------
   5. Combine everything per race
-----------------------------------------------------------------------------*/
race_summary AS (
    SELECT  so.race_id,
            COALESCE(er.retirements, 0)      AS retirements,
            COALESCE(ep.pit_stops,   0)      AS pit_stops,
            so.start_related                  AS start_related,
            /* standard on‑track passes = all raw on‑track gains
               minus the gains that were consequences of pits/retirements    */
            (otr.raw_ontrack
               - COALESCE(ep.pit_stops, 0)
               - COALESCE(er.retirements, 0)
            )                                AS standard_on_track
    FROM    start_overtakes        so
    JOIN    ontrack_overtakes_raw  otr ON otr.race_id = so.race_id
    LEFT JOIN early_pits           ep  ON ep .race_id = so.race_id
    LEFT JOIN early_rets           er  ON er.race_id = so.race_id
),

/* --------------------------------------------------------------------------
   6. Aggregate over all races (overall answer)
-----------------------------------------------------------------------------*/
overall AS (
    SELECT  SUM(retirements)       AS retirements,
            SUM(pit_stops)         AS pit_stops,
            SUM(start_related)     AS start_related,
            SUM(standard_on_track) AS standard_on_track
    FROM    race_summary
)

SELECT *
FROM   overall;