WITH trips_period AS (   -- rides between 2014-01-01 and 2017-12-31
    SELECT *
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS
    WHERE TO_TIMESTAMP("start_date" / 1000000)
          BETWEEN '2014-01-01' AND '2017-12-31 23:59:59'
),
trips_station AS (       -- add station / region information
    SELECT
        t.*,
        si."region_id"
    FROM trips_period t
    LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO si
           ON CAST(si."station_id" AS NUMBER) = t."start_station_id"
),
trip_region AS (         -- derive region name and pick the latest ride per region
    SELECT
        COALESCE(r."name", 'San Francisco')                      AS "REGION",
        t."trip_id"                                              AS "TRIP_ID",
        t."duration_sec"                                         AS "RIDE_DURATION_SEC",
        TO_TIMESTAMP(t."start_date" / 1000000)                   AS "START_TIME",
        t."start_station_name"                                   AS "START_STATION",
        t."member_gender"                                        AS "RIDER_GENDER",
        ROW_NUMBER() OVER (
            PARTITION BY COALESCE(r."name", 'San Francisco')
            ORDER BY t."start_date" DESC NULLS LAST
        )                                                        AS rn
    FROM trips_station t
    LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_REGIONS r
           ON r."region_id" = t."region_id"
)

SELECT
    "REGION",
    "TRIP_ID",
    "RIDE_DURATION_SEC",
    "START_TIME",
    "START_STATION",
    "RIDER_GENDER"
FROM trip_region
WHERE rn = 1
ORDER BY "REGION";