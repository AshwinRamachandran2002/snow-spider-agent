SELECT MAX("daily_count") AS "max_daily_rides"
FROM (
    SELECT DATE_TRUNC('DAY', TO_TIMESTAMP_NTZ("start_time" / 1000000)) AS "ride_date",
           COUNT(*) AS "daily_count"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS
    WHERE "bike_type" = 'electric'
      AND "duration_minutes" > 10
      AND "subscriber_type" = 'Student Membership'
      AND "start_station_name" NOT ILIKE '%Mobile Station%'
      AND "end_station_name"   NOT ILIKE '%Mobile Station%'
      AND "start_station_name" NOT ILIKE '%Repair Shop%'
      AND "end_station_name"   NOT ILIKE '%Repair Shop%'
    GROUP BY "ride_date"
) AS daily_stats;