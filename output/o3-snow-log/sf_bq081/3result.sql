WITH trips_with_region AS (
    SELECT
        /* -------- approximate geographic buckets for Bay Area bikeshare zones -------- */
        CASE
            WHEN t."start_station_longitude" <= -122.35                            THEN 'San Francisco'
            WHEN t."start_station_longitude" >  -122.35
                 AND t."start_station_longitude" <= -122.00                         THEN 'Oakland'
            ELSE 'San Jose'
        END                                                      AS region_name,
        t."trip_id",
        t."duration_sec",
        t."start_date",
        t."start_station_name",
        t."member_gender",
        ROW_NUMBER() OVER (
            PARTITION BY
                CASE
                    WHEN t."start_station_longitude" <= -122.35                    THEN 'San Francisco'
                    WHEN t."start_station_longitude" >  -122.35
                         AND t."start_station_longitude" <= -122.00                 THEN 'Oakland'
                    ELSE 'San Jose'
                END
            ORDER BY t."start_date" DESC NULLS LAST
        )                                                      AS rn
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS t
    WHERE t."start_date" BETWEEN 1388534400000000   -- 2014-01-01 00:00:00
                           AND     1514764799000000 -- 2017-12-31 23:59:59
          AND t."start_station_longitude" IS NOT NULL
          AND t."start_station_latitude"  IS NOT NULL
)

SELECT
    region_name                 AS "REGION_NAME",
    "trip_id"                   AS "TRIP_ID",
    "duration_sec"              AS "RIDE_DURATION_SEC",
    TO_TIMESTAMP("start_date" / 1000000) AS "START_TIME",
    "start_station_name"        AS "STARTING_STATION",
    "member_gender"             AS "RIDER_GENDER"
FROM trips_with_region
WHERE rn = 1
ORDER BY region_name;