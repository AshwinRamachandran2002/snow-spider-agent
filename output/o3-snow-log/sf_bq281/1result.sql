WITH filtered_rides AS (
    SELECT
        DATE(TO_TIMESTAMP("start_time" / 1000000)) AS ride_date
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS
    WHERE "subscriber_type" = 'Student Membership'
      AND "bike_type" = 'electric'
      AND "duration_minutes" > 10
      AND UPPER("start_station_name") NOT LIKE '%MOBILE STATION%'
      AND UPPER("end_station_name")   NOT LIKE '%MOBILE STATION%'
      AND UPPER("start_station_name") NOT LIKE '%REPAIR SHOP%'
      AND UPPER("end_station_name")   NOT LIKE '%REPAIR SHOP%'
),
daily_counts AS (
    SELECT
        ride_date,
        COUNT(*) AS ride_count
    FROM filtered_rides
    GROUP BY ride_date
)
SELECT
    MAX(ride_count) AS highest_ride_count
FROM daily_counts;