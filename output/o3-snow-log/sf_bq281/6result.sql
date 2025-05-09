WITH filtered_rides AS (
    SELECT
        DATE_TRUNC('day', TO_TIMESTAMP("start_time" / 1000000)) AS ride_date
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS
    WHERE
        "subscriber_type" = 'Student Membership'
        AND "bike_type" = 'electric'
        AND "duration_minutes" > 10
        AND "start_station_name" NOT ILIKE '%Mobile Station%'
        AND "end_station_name"   NOT ILIKE '%Mobile Station%'
        AND "start_station_name" NOT ILIKE '%Repair Shop%'
        AND "end_station_name"   NOT ILIKE '%Repair Shop%'
),
daily_counts AS (
    SELECT
        ride_date,
        COUNT(*) AS daily_ride_count
    FROM filtered_rides
    GROUP BY ride_date
)
SELECT
    MAX(daily_ride_count) AS highest_daily_rides
FROM daily_counts;