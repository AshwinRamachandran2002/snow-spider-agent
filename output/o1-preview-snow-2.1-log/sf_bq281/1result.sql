SELECT MAX(daily_ride_count) AS "Highest_number_of_rides"
FROM (
    SELECT DATE(TO_TIMESTAMP("start_time" / 1000000)) AS ride_date,
           COUNT(*) AS daily_ride_count
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS
    WHERE "bike_type" = 'electric'
      AND "duration_minutes" > 10
      AND ("subscriber_type" = 'Student Membership' OR "subscriber_type" = 'U.T. Student Membership')
      AND "start_station_name" NOT ILIKE '%Mobile Station%'
      AND "end_station_name" NOT ILIKE '%Mobile Station%'
      AND "start_station_name" NOT ILIKE '%Repair Shop%'
      AND "end_station_name" NOT ILIKE '%Repair Shop%'
    GROUP BY DATE(TO_TIMESTAMP("start_time" / 1000000))
) sub;