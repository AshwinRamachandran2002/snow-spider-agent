WITH filtered_trips AS (
    SELECT
        TO_DATE(TO_TIMESTAMP("start_time" / 1000000)) AS ride_date
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS
    WHERE "bike_type" = 'electric'
      AND "duration_minutes" > 10
      AND "subscriber_type" = 'Student Membership'
      AND (
            ("start_station_name" IS NULL OR (
                 "start_station_name" NOT ILIKE '%Mobile Station%' 
             AND "start_station_name" NOT ILIKE '%Repair Shop%'))
        AND ("end_station_name"   IS NULL OR (
                 "end_station_name"   NOT ILIKE '%Mobile Station%' 
             AND "end_station_name"   NOT ILIKE '%Repair Shop%'))
          )
), daily_totals AS (
    SELECT
        ride_date,
        COUNT(*) AS rides_count
    FROM filtered_trips
    GROUP BY ride_date
)
SELECT
    MAX(rides_count) AS highest_rides_in_single_day
FROM daily_totals;