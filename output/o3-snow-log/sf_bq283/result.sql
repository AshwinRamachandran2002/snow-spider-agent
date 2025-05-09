/* 1. Identify stations that are currently active  
      (any status value other than 'closed' is treated as active).        */
WITH active_stations AS (
    SELECT "station_id"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS
    WHERE LOWER("status") <> 'closed'
),

/* 2. Aggregate trip counts and average duration for trips that
      start at an active station.                                          */
station_trip_stats AS (
    SELECT
        t."start_station_id"                              AS "station_id",
        COUNT(*)                                          AS "total_start_trips",
        AVG(t."duration_minutes")                         AS "avg_duration_minutes"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t
    JOIN active_stations s
          ON t."start_station_id" = s."station_id"
    GROUP BY t."start_station_id"
),

/* 3. Get overall total number of starting trips from active stations.     */
overall_total AS (
    SELECT SUM("total_start_trips") AS "overall_total_trips"
    FROM   station_trip_stats
),

/* 4. Rank stations by total starting trips (descending).                  */
ranked_stations AS (
    SELECT
        sts."station_id",
        sts."total_start_trips",
        ROUND( 100.0 * sts."total_start_trips"
               / ot."overall_total_trips", 4)            AS "percentage_of_total_trips",
        ROUND(sts."avg_duration_minutes", 4)              AS "avg_duration_minutes",
        DENSE_RANK() OVER (ORDER BY sts."total_start_trips" DESC) AS "rank"
    FROM station_trip_stats sts
    CROSS JOIN overall_total ot
)

/* 5. Return stations whose rank is within the top 15 (including ties).    */
SELECT
    "station_id",
    "total_start_trips",
    "percentage_of_total_trips",
    "avg_duration_minutes"
FROM ranked_stations
WHERE "rank" <= 15
ORDER BY "rank" ASC, "station_id" ASC;