SELECT MAX("trip_count") AS "Highest_number_of_rides" FROM (
  SELECT TO_DATE(TO_TIMESTAMP_NTZ("start_time" / 1000000)) AS "date", COUNT(*) AS "trip_count"
  FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS
  WHERE LOWER("bike_type") = 'electric'
    AND "duration_minutes" > 10
    AND "subscriber_type" ILIKE '%Student Membership%'
    AND "start_station_name" NOT ILIKE '%Mobile Station%' AND "start_station_name" NOT ILIKE '%Repair Shop%'
    AND "end_station_name" NOT ILIKE '%Mobile Station%' AND "end_station_name" NOT ILIKE '%Repair Shop%'
  GROUP BY "date"
);