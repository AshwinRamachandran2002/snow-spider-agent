WITH trips_2017 AS (
    SELECT
        t."trip_id",
        t."duration_sec",
        TO_TIMESTAMP(t."start_date" / 1000000)              AS start_ts,
        t."start_station_name",
        t."end_station_name",
        t."bike_number",
        t."subscriber_type",
        t."member_birth_year",
        t."member_gender",
        t."start_station_id"
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS t
    WHERE
        TO_TIMESTAMP(t."start_date" / 1000000) BETWEEN '2017-07-01' AND '2017-12-31 23:59:59'
        AND t."start_station_name" IS NOT NULL
        AND t."member_birth_year"   IS NOT NULL
        AND t."member_gender"       IS NOT NULL
)
SELECT
    tr."trip_id"                                                     AS "TRIP_ID",
    tr."duration_sec"                                                AS "DURATION_SEC",
    tr.start_ts                                                      AS "START_DATE",
    tr."start_station_name"                                          AS "START_STATION_NAME",
    tr."start_station_name" || ' - ' || tr."end_station_name"        AS "ROUTE",
    tr."bike_number"                                                 AS "BIKE_NUMBER",
    tr."subscriber_type"                                             AS "SUBSCRIBER_TYPE",
    tr."member_birth_year"                                           AS "MEMBER_BIRTH_YEAR",
    DATE_PART('year', CURRENT_DATE()) - tr."member_birth_year"       AS "AGE",
    CASE
        WHEN DATE_PART('year', CURRENT_DATE()) - tr."member_birth_year" < 40  THEN 'Young (<40 Y.O)'
        WHEN DATE_PART('year', CURRENT_DATE()) - tr."member_birth_year" <= 60 THEN 'Adult (40-60 Y.O)'
        ELSE 'Senior Adult (>60 Y.O)'
    END                                                              AS "AGE_CLASSIFICATION",
    tr."member_gender"                                               AS "MEMBER_GENDER",
    COALESCE(r."name", 'Unknown')                                    AS "REGION_NAME"
FROM trips_2017 tr
LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO si
       ON si."station_id" = CAST(tr."start_station_id" AS TEXT)
LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_REGIONS r
       ON r."region_id" = si."region_id"
ORDER BY tr."duration_sec" DESC NULLS LAST
LIMIT 5;