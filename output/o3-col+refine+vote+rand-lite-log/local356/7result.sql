WITH deltas AS (               -- lap-to-lap position changes on track
    SELECT  curr.driver_id,
            (prev.position - curr.position) AS gain          -- +ve = overtook, ‑ve = was overtaken
    FROM    lap_positions AS curr
    JOIN    lap_positions AS prev
           ON  curr.race_id  = prev.race_id
           AND curr.driver_id = prev.driver_id
           AND curr.lap       = prev.lap + 1                 -- consecutive laps
    LEFT JOIN retirements AS r                               -- exclude laps after retirement
           ON  curr.race_id  = r.race_id
           AND curr.driver_id = r.driver_id
    WHERE   curr.lap_type = 'Race'                           -- ignore pit-in / pit-out / start grid rows
      AND   prev.lap_type = 'Race'
      AND   curr.lap  > 1                                    -- skip start-lap movements (lap 0 → 1)
      AND  (r.lap IS NULL OR curr.lap < r.lap)               -- only laps before a retirement
), agg AS (               -- aggregate overtakes vs. times being overtaken
    SELECT  driver_id,
            SUM(CASE WHEN gain > 0 THEN 1 ELSE 0 END) AS overtakes_made,
            SUM(CASE WHEN gain < 0 THEN 1 ELSE 0 END) AS times_overtaken
    FROM    deltas
    GROUP BY driver_id
)
SELECT  d.full_name
FROM    agg
JOIN    drivers AS d USING (driver_id)
WHERE   times_overtaken > overtakes_made                     -- net negative on-track balance
ORDER BY d.full_name;