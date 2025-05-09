WITH trips_filtered AS (
    SELECT
        "trip_id",
        "duration_sec",
        TO_TIMESTAMP("start_date" / 1000000) AS start_time,
        "start_station_id",
        "start_station_name",
        "member_gender"
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS
    WHERE TO_TIMESTAMP("start_date" / 1000000)
          BETWEEN '2014-01-01' AND '2017-12-31 23:59:59'
)
SELECT
    COALESCE(r."name", 'Unknown')         AS region_name,
    tf."trip_id",
    tf."duration_sec",
    tf.start_time,
    tf."start_station_name",
    tf."member_gender"
FROM trips_filtered tf
LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO s
       ON s."station_id" = TO_VARCHAR(tf."start_station_id")
LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_REGIONS r
       ON s."region_id" = r."region_id"
QUALIFY ROW_NUMBER() OVER (
            PARTITION BY COALESCE(r."name", 'Unknown')
            ORDER BY tf.start_time DESC NULLS LAST
        ) = 1
ORDER BY region_name;