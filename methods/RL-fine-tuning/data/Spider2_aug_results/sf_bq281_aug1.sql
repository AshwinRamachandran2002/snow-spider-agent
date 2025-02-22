-- Task: For each date, find the number of electric bike rides lasting more than 10 minutes taken by subscribers with 'Student Membership', excluding rides starting or ending at 'Mobile Station' or 'Repair Shop'.
SELECT TO_DATE(TO_TIMESTAMP_NTZ("start_time" / 1000000)) AS "date", COUNT(*) AS "trip_count"
FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS
WHERE LOWER("bike_type") = 'electric'
  AND "duration_minutes" > 10
  AND "subscriber_type" ILIKE '%Student Membership%'
  AND "start_station_name" NOT ILIKE '%Mobile Station%'
  AND "start_station_name" NOT ILIKE '%Repair Shop%'
  AND "end_station_name" NOT ILIKE '%Mobile Station%'
  AND "end_station_name" NOT ILIKE '%Repair Shop%'
GROUP BY "date";