WITH active_stations AS (      -- 1. keep only stations that are currently “active”
    SELECT "station_id"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS
    WHERE LOWER("status") = 'active'
),

station_trips AS (            -- 2. trips that START at those active stations
    SELECT 
        t."start_station_id"          AS station_id,
        COUNT(*)                      AS total_trips,
        AVG(t."duration_minutes")     AS avg_duration
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t
    JOIN active_stations s 
          ON t."start_station_id" = s."station_id"
    GROUP BY t."start_station_id"
),

overall AS (                  -- 3. grand-total of all starting trips from active stations
    SELECT SUM(total_trips) AS overall_total
    FROM station_trips
),

ranked AS (                   -- 4. compute share %, average duration, and dense rank
    SELECT
        st.station_id,
        st.total_trips,
        ROUND(st.total_trips / overall.overall_total * 100, 4)  AS pct_of_total,
        ROUND(st.avg_duration, 4)                               AS avg_duration,
        DENSE_RANK() OVER (ORDER BY st.total_trips DESC)        AS rnk
    FROM station_trips st
    CROSS JOIN overall
)

-- 5. keep the top-15 ranks (including ties) and return final result
SELECT
    station_id,
    total_trips,
    pct_of_total,
    avg_duration
FROM ranked
WHERE rnk <= 15
ORDER BY rnk, station_id;