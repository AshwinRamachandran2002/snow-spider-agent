WITH filtered AS (
    SELECT
        TO_DATE(TO_TIMESTAMP("start_time" / 1000000)) AS ride_date
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS
    WHERE "subscriber_type" = 'Student Membership'
      AND "bike_type" = 'electric'
      AND "duration_minutes" > 10
      AND COALESCE("start_station_name", '') NOT ILIKE '%Mobile Station%'
      AND COALESCE("start_station_name", '') NOT ILIKE '%Repair Shop%'
      AND COALESCE("end_station_name",   '') NOT ILIKE '%Mobile Station%'
      AND COALESCE("end_station_name",   '') NOT ILIKE '%Repair Shop%'
), daily_counts AS (
    SELECT
        ride_date,
        COUNT(*) AS rides
    FROM filtered
    GROUP BY ride_date
)
SELECT
    MAX(rides) AS "max_daily_electric_student_rides_over10min"
FROM daily_counts;