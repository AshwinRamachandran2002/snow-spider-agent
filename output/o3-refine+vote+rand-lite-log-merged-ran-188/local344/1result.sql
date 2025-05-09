WITH RECURSIVE

/* 1) Races that have at least one recorded pit-stop */
races_with_pit AS (
    SELECT DISTINCT race_id
    FROM pit_stops
),

/* 2) How many places every driver gained between consecutive laps */
pos_change AS (
    SELECT   curr.race_id,
             curr.driver_id,
             curr.lap,
             prev.position - curr.position        AS positions_gained
    FROM     lap_positions AS curr
    JOIN     lap_positions AS prev
           ON prev.race_id   = curr.race_id
          AND prev.driver_id = curr.driver_id
          AND prev.lap       = curr.lap - 1
    WHERE    curr.race_id IN (SELECT race_id FROM races_with_pit)
      AND    (prev.position - curr.position) > 0          -- gained places
),

/* 3) Turn a multi-place gain into one row per individual pass            */
tally(n) AS (                       -- simple 1…N counter (N=50 is safe)
    SELECT 1
    UNION ALL
    SELECT n+1 FROM tally WHERE n < 50
),
individual_passes AS (
    SELECT pc.race_id,
           pc.driver_id  AS overtaker_id,
           pc.lap,
           t.n           AS pass_no
    FROM   pos_change pc
    JOIN   tally t
      ON   t.n <= pc.positions_gained
),

/* 4) Identify which driver was overtaken on that exact lap               */
overtaken AS (
    SELECT   curr.race_id,
             curr.driver_id AS overtaken_id,
             curr.lap
    FROM     lap_positions AS curr
    JOIN     lap_positions AS prev
           ON prev.race_id   = curr.race_id
          AND prev.driver_id = curr.driver_id
          AND prev.lap       = curr.lap - 1
    WHERE    curr.position - prev.position = 1         -- lost one place
),

/* 5) Pair overtaker with the driver he passed                             */
pass_pairs AS (
    SELECT ip.race_id,
           ip.lap,
           ip.overtaker_id,
           o.overtaken_id
    FROM   individual_passes ip
    JOIN   overtaken        o
      ON   o.race_id = ip.race_id
     AND   o.lap     = ip.lap
),

/* 6) Classify every pass                                                  */
pass_types AS (
    SELECT pp.*,
           CASE
               WHEN pp.lap = 1
                    THEN 'race_start'
               WHEN EXISTS ( SELECT 1
                             FROM retirements r
                             WHERE r.race_id  = pp.race_id
                               AND r.driver_id = pp.overtaken_id
                               AND r.lap       = pp.lap )
                    THEN 'retirement'
               WHEN EXISTS ( SELECT 1
                             FROM pit_stops ps
                             WHERE ps.race_id  = pp.race_id
                               AND ps.driver_id = pp.overtaken_id
                               AND ps.lap       = pp.lap )
                    THEN 'pit_entry'
               WHEN EXISTS ( SELECT 1
                             FROM pit_stops ps
                             WHERE ps.race_id  = pp.race_id
                               AND ps.driver_id = pp.overtaker_id
                               AND ps.lap       = pp.lap )
                    THEN 'pit_exit'
               ELSE 'on_track'
           END AS overtake_type
    FROM   pass_pairs pp
)

/* 7) Final count of each overtake type                                    */
SELECT   overtake_type,
         COUNT(*) AS num_overtakes
FROM     pass_types
GROUP BY overtake_type
ORDER BY num_overtakes DESC;