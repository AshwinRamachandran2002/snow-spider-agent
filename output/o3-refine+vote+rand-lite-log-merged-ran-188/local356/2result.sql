WITH pit AS (                               -- every pit-stop entry lap
    SELECT race_id,
           driver_id,
           lap
    FROM   pit_stops
),
lap_changes AS (                            -- lap-to-lap position deltas on real race laps
    SELECT  race_id,
            driver_id,
            lap,
            position,
            LAG(position) OVER (PARTITION BY race_id, driver_id
                                ORDER BY lap) AS prev_pos
    FROM    lap_positions
    WHERE   lap_type = 'Race'
),
on_track_moves AS (                         -- keep laps that are NOT related to own pit entry/exit
    SELECT lc.*
    FROM   lap_changes lc
    LEFT   JOIN pit p_in   -- pit-entry lap
           ON  p_in.race_id  = lc.race_id
           AND p_in.driver_id = lc.driver_id
           AND p_in.lap       = lc.lap
    LEFT   JOIN pit p_out  -- first lap after leaving the pits
           ON  p_out.race_id  = lc.race_id
           AND p_out.driver_id = lc.driver_id
           AND p_out.lap       = lc.lap - 1
    WHERE  lc.prev_pos IS NOT NULL          -- need a previous-lap reference
      AND  lc.lap       > 1                 -- ignore start-lap changes
      AND  p_in.lap  IS NULL                -- exclude pit entry laps
      AND  p_out.lap IS NULL                -- exclude first lap after pit exit
),
driver_totals AS (                          -- aggregate overtakes vs. being overtaken
    SELECT  driver_id,
            SUM(CASE WHEN prev_pos > position THEN 1 ELSE 0 END) AS overtakes_made,
            SUM(CASE WHEN prev_pos < position THEN 1 ELSE 0 END) AS times_overtaken
    FROM    on_track_moves
    GROUP BY driver_id
)
SELECT DISTINCT
       d.forename || ' ' || d.surname AS full_name
FROM   driver_totals dt
JOIN   drivers       d ON d.driver_id = dt.driver_id
WHERE  dt.times_overtaken > dt.overtakes_made
ORDER  BY full_name;