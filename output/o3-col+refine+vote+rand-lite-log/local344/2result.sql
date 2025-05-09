/* 1.  Races that contain full pit-stop information */
WITH races_with_pit AS (
    SELECT race_id
    FROM races_ext
    WHERE is_pit_data_available = 1
),

/* 2.  Current lap vs. previous lap for every driver in those races      */
lap_pairs AS (
    SELECT
        cur.race_id,
        cur.driver_id,
        cur.lap                          AS cur_lap,
        cur.position                     AS cur_pos,
        prev.position                    AS prev_pos,
        cur.lap_type                     AS cur_lap_type,
        prev.lap_type                    AS prev_lap_type
    FROM   lap_positions AS cur
           JOIN races_with_pit   USING (race_id)
           JOIN lap_positions AS prev
                 ON  prev.race_id  = cur.race_id
                 AND prev.driver_id = cur.driver_id
                 AND prev.lap       = cur.lap - 1
),

/* 3.  Laps on which the driver LOST position(s) – i.e., was not behind
        the other car on the previous lap but is now behind it            */
overtake_events AS (
    SELECT
        lp.*,
        (cur_pos - prev_pos) AS positions_lost        -- positive value
    FROM   lap_pairs lp
    WHERE  (cur_pos - prev_pos) > 0                   -- driver is now behind
),

/* 4.  Classify the reason for every position loss                         */
classified AS (
    SELECT
        oe.*,
        CASE
            /* grid → lap-1 jump  = “start” overtake                        */
            WHEN oe.prev_lap_type NOT LIKE 'Race%' 
                 AND oe.cur_lap_type  LIKE 'Race%'                         THEN 'start'

            /* lost position on the retirement lap                         */
            WHEN oe.cur_lap_type  LIKE 'Retirement%'                       THEN 'retirement'

            /* lap on which the driver entered the pits                    */
            WHEN EXISTS (SELECT 1
                         FROM   pit_stops ps
                         WHERE  ps.race_id  = oe.race_id
                           AND  ps.driver_id = oe.driver_id
                           AND  ps.lap       = oe.cur_lap)                THEN 'pit_stop'

            /* everything else is treated as a normal, on-track pass       */
            ELSE 'on_track'
        END AS overtake_type
    FROM   overtake_events oe
)

/* 5.  Total number of overtakes by category                               */
SELECT   overtake_type,
         SUM(positions_lost) AS overtake_count
FROM     classified
GROUP BY overtake_type
ORDER BY overtake_count DESC;