WITH race_lap_positions AS (
    /* 1) keep only laps from races that have pit‑stop data               */
    SELECT lp.race_id ,
           lp.driver_id ,
           lp.lap ,
           lp.position ,
           lp.lap_type
    FROM   lap_positions        lp
    JOIN   races_ext            re  USING (race_id)
    WHERE  re.is_pit_data_available = 1
),

position_deltas AS (
    /* 2) for every driver get the previous lap’s position & lap_type     */
    SELECT race_id ,
           driver_id ,
           lap ,
           position                          AS curr_pos ,
           lap_type                          AS curr_type ,
           LAG(position)  OVER w             AS prev_pos ,
           LAG(lap_type) OVER w              AS prev_type
    FROM   race_lap_positions
    WINDOW w AS (PARTITION BY race_id, driver_id ORDER BY lap)
),

overtake_events AS (
    /* 3) keep laps where the driver MOVED FORWARD (overtook)             */
    SELECT race_id ,
           driver_id ,
           lap ,
           (prev_pos - curr_pos)             AS gained_places ,   -- 1 place = 1 overtake
           curr_type ,
           prev_type
    FROM   position_deltas
    WHERE  prev_pos IS NOT NULL
      AND  prev_pos  > curr_pos              -- driver gained one or more positions
),

classified_events AS (
    /* 4) classify each gain into one of the requested over‑take types    */
    SELECT CASE
               WHEN curr_type LIKE '%Pit Exit%'      THEN 'Pit Exit'
               WHEN prev_type LIKE '%Pit Entry%'     THEN 'Pit Entry'
               WHEN prev_type LIKE 'Starting%'       THEN 'Race Start'
               WHEN curr_type LIKE '%Retire%'        THEN 'Retirement'
               ELSE                                        'On‑track'
           END                                        AS overtake_type ,
           gained_places
    FROM   overtake_events
)

/* 5) final count per over‑take type                                       */
SELECT   overtake_type ,
         SUM(gained_places) AS total_overtakes
FROM     classified_events
GROUP BY overtake_type
ORDER BY total_overtakes DESC;