SELECT MAX("Ride_Count") AS "Highest_number_of_rides"
FROM (
  SELECT TO_DATE(TO_TIMESTAMP_LTZ("start_time" / 1000)) AS "ride_date", COUNT(*) AS "Ride_Count"
  FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS
  WHERE "subscriber_type" = 'Student Membership'
    AND "bike_type" = 'electric'
    AND "duration_minutes" > 10
    AND "start_station_name" NOT ILIKE '%Mobile Station%'
    AND "start_station_name" NOT ILIKE '%Repair Shop%'
    AND "end_station_name" NOT ILIKE '%Mobile Station%'
    AND "end_station_name" NOT ILIKE '%Repair Shop%'
  GROUP BY "ride_date"
);