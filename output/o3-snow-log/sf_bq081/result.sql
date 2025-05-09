WITH trip_details AS (
    SELECT
        COALESCE(rg."name", 'Unknown')                    AS "region_name",
        tr."trip_id",
        tr."duration_sec",
        TO_TIMESTAMP_NTZ(tr."start_date" / 1000000)       AS "start_time",
        tr."start_station_name",
        tr."member_gender",
        ROW_NUMBER() OVER (
            PARTITION BY COALESCE(rg."name", 'Unknown')
            ORDER BY tr."start_date" DESC NULLS LAST, tr."trip_id" DESC
        )                                                 AS rn
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS         tr
    LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO si
           ON TRY_TO_NUMBER(si."station_id") = tr."start_station_id"
    LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_REGIONS  rg
           ON rg."region_id" = si."region_id"
    WHERE TO_TIMESTAMP_NTZ(tr."start_date" / 1000000) >= '2014-01-01'
      AND TO_TIMESTAMP_NTZ(tr."start_date" / 1000000) <  '2018-01-01'
)
SELECT
    "region_name"            AS "REGION_NAME",
    "trip_id"                AS "TRIP_ID",
    "duration_sec"           AS "RIDE_DURATION_SEC",
    "start_time"             AS "START_TIME",
    "start_station_name"     AS "STARTING_STATION",
    "member_gender"          AS "RIDER_GENDER"
FROM trip_details
WHERE rn = 1
ORDER BY "region_name";