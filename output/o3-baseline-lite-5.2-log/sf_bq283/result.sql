WITH active_stations AS (
    SELECT 
        "station_id"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS
    -- treat anything not explicitly marked “closed” as active
    WHERE "status" IS NULL 
       OR LOWER("status") <> 'closed'
), 

trips_from_active AS (
    SELECT  
        t."start_station_id"         AS "station_id",
        t."duration_minutes"         AS "duration_minutes"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t
    JOIN active_stations s
      ON t."start_station_id" = s."station_id"
), 

station_totals AS (
    SELECT
        "station_id",
        COUNT(*)                     AS "total_start_trips",
        AVG("duration_minutes")      AS "avg_duration_minutes"
    FROM trips_from_active
    GROUP BY "station_id"
),  

overall AS (
    SELECT SUM("total_start_trips") AS "all_start_trips"
    FROM   station_totals
), 

ranked AS (
    SELECT
        st."station_id",
        st."total_start_trips",
        (st."total_start_trips" / o."all_start_trips") * 100  AS "pct_of_active_trips",
        st."avg_duration_minutes",
        DENSE_RANK() OVER (ORDER BY st."total_start_trips" DESC) AS "rank"
    FROM station_totals st, overall o
)

SELECT
    "station_id",
    "total_start_trips",
    ROUND("pct_of_active_trips", 4)   AS "pct_of_active_trips",
    ROUND("avg_duration_minutes", 4)  AS "avg_duration_minutes"
FROM ranked
WHERE "rank" <= 15
ORDER BY "rank", "station_id";