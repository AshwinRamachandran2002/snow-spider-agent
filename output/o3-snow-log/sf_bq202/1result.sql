WITH trips_with_ts AS (  -- add a real timestamp column
    SELECT
        "start_station_name",
        TO_TIMESTAMP("starttime" / 1000000)             AS ts
    FROM NEW_YORK_PLUS.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS
    WHERE EXTRACT(year FROM TO_TIMESTAMP("starttime" / 1000000)) = 2018
),

-- find the station with the most 2018 trip starts
top_start_station AS (
    SELECT
        "start_station_name",
        COUNT(*) AS trip_cnt,
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rn
    FROM trips_with_ts
    GROUP BY "start_station_name"
    QUALIFY rn = 1          -- keep only the #1 station
),

-- trips that began at that top station
station_trips AS (
    SELECT t.ts
    FROM trips_with_ts t
    JOIN top_start_station s
      ON t."start_station_name" = s."start_station_name"
),

-- count trips by day-of-week and hour
dow_hr_counts AS (
    SELECT
        EXTRACT(DAYOFWEEK FROM ts) AS numeric_day_of_week,   -- 1=Sunday … 7=Saturday
        EXTRACT(HOUR      FROM ts) AS hour_of_day,           -- 0-23
        COUNT(*)                      AS trip_cnt,
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rn
    FROM station_trips
    GROUP BY numeric_day_of_week, hour_of_day
)

-- the most common (day, hour) combination
SELECT
    numeric_day_of_week,
    hour_of_day
FROM dow_hr_counts
WHERE rn = 1;