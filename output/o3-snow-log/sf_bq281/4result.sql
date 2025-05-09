-- highest number of qualifying electric–bike trips taken in one day
SELECT 
       "daily_rides" AS "highest_daily_ride_count"
FROM (
         SELECT 
                DATE_TRUNC('day', TO_TIMESTAMP("start_time" / 1000000)) AS "ride_date",
                COUNT(*) AS "daily_rides"
         FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS
         WHERE "subscriber_type" = 'Student Membership'
           AND "bike_type" = 'electric'
           AND "duration_minutes" > 10
           AND "start_station_name" NOT ILIKE '%Mobile Station%'
           AND "start_station_name" NOT ILIKE '%Repair Shop%'
           AND "end_station_name"   NOT ILIKE '%Mobile Station%'
           AND "end_station_name"   NOT ILIKE '%Repair Shop%'
         GROUP BY "ride_date"
     ) AS daily_counts
ORDER BY "daily_rides" DESC NULLS LAST
LIMIT 1;