WITH "FILTERED_TRIPS" AS (
    SELECT 
        TO_DATE(TO_TIMESTAMP_NTZ("start_time" / 1000)) AS "ride_date"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS
    WHERE 
        "bike_type" ILIKE 'electric'                          -- electric bikes only
        AND "duration_minutes" > 10                           -- trips longer than 10 minutes
        AND "subscriber_type" = 'Student Membership'          -- subscriber type filter
        AND "start_station_name" NOT ILIKE '%Mobile Station%' -- exclude Mobile Station starts
        AND "end_station_name"   NOT ILIKE '%Mobile Station%' -- exclude Mobile Station ends
        AND "start_station_name" NOT ILIKE '%Repair Shop%'    -- exclude Repair Shop starts
        AND "end_station_name"   NOT ILIKE '%Repair Shop%'    -- exclude Repair Shop ends
)
SELECT MAX("daily_rides") AS "highest_daily_ride_count"
FROM (
    SELECT 
        "ride_date",
        COUNT(*) AS "daily_rides"
    FROM "FILTERED_TRIPS"
    GROUP BY "ride_date"
) AS "D";