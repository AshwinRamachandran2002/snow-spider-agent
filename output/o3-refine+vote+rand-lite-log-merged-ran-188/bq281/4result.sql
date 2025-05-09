WITH filtered_rides AS (
    SELECT
        DATE(start_time) AS ride_date
    FROM
        `bigquery-public-data.austin_bikeshare.bikeshare_trips`
    WHERE
        subscriber_type = 'Student Membership'                  -- only student members
        AND bike_type = 'electric'                              -- only e‑bikes
        AND duration_minutes > 10                               -- rides longer than 10 min
        AND NOT (
            LOWER(start_station_name) LIKE '%mobile station%'   -- exclude mobile/repair starts
            OR LOWER(start_station_name) LIKE '%repair shop%'
            OR LOWER(end_station_name)   LIKE '%mobile station%'-- exclude mobile/repair ends
            OR LOWER(end_station_name)   LIKE '%repair shop%'
        )
),
daily_counts AS (
    SELECT
        ride_date,
        COUNT(*) AS rides_in_day
    FROM
        filtered_rides
    GROUP BY
        ride_date
)
SELECT
    MAX(rides_in_day) AS highest_daily_electric_student_rides_over_10min
FROM
    daily_counts;