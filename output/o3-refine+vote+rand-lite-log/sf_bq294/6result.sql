WITH trips AS (
    SELECT
        t."trip_id",
        t."duration_sec",
        TO_TIMESTAMP(t."start_date" / 1000000)                                  AS "start_ts",
        t."start_station_name",
        t."end_station_name",
        t."bike_number",
        t."subscriber_type",
        TRY_CAST(t."member_birth_year" AS INT)                                  AS "birth_year",
        t."member_gender",
        t."start_station_id"
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS t
    -- keep rows whose start datetime is in the target window
    WHERE TO_TIMESTAMP(t."start_date" / 1000000)
          BETWEEN '2017-07-01' AND '2017-12-31 23:59:59'
)
SELECT
    tr."trip_id"                                                               AS "TRIP_ID",
    tr."duration_sec"                                                          AS "DURATION_SEC",
    tr."start_ts"                                                              AS "START_DATE",
    tr."start_station_name"                                                    AS "START_STATION_NAME",
    tr."start_station_name" || ' - ' || tr."end_station_name"                  AS "ROUTE",
    tr."bike_number"                                                           AS "BIKE_NUMBER",
    tr."subscriber_type"                                                       AS "SUBSCRIBER_TYPE",
    tr."birth_year"                                                            AS "MEMBER_BIRTH_YEAR",
    (EXTRACT(year FROM CURRENT_DATE) - tr."birth_year")                        AS "AGE",
    CASE
        WHEN (EXTRACT(year FROM CURRENT_DATE) - tr."birth_year") < 40  THEN 'Young (<40 Y.O)'
        WHEN (EXTRACT(year FROM CURRENT_DATE) - tr."birth_year") <= 60 THEN 'Adult (40-60 Y.O)'
        ELSE 'Senior Adult (>60 Y.O)'
    END                                                                        AS "AGE_CLASS",
    tr."member_gender"                                                         AS "MEMBER_GENDER",
    reg."name"                                                                 AS "REGION_NAME"
FROM trips tr
LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO si
       ON si."station_id" = tr."start_station_id"::TEXT
LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_REGIONS reg
       ON reg."region_id" = si."region_id"
-- exclude rows with missing critical information
WHERE tr."start_station_name" IS NOT NULL
  AND tr."end_station_name"   IS NOT NULL
  AND tr."member_gender"      IS NOT NULL
  AND tr."birth_year"         IS NOT NULL
ORDER BY tr."duration_sec" DESC NULLS LAST, tr."trip_id"
LIMIT 5;