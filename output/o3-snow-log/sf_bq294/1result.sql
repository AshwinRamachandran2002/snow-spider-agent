WITH trips_filtered AS (
    SELECT
        "trip_id",
        "duration_sec",
        TO_TIMESTAMP("start_date" / 1000000)            AS start_ts,
        "start_station_name",
        "end_station_name",
        "bike_number",
        "subscriber_type",
        "member_birth_year",
        "member_gender",
        "start_station_id"
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS
    WHERE "start_station_name" IS NOT NULL
      AND "member_birth_year" IS NOT NULL
      AND "member_gender"     IS NOT NULL
      AND TO_DATE(TO_TIMESTAMP("start_date" / 1000000))
          BETWEEN '2017-07-01' AND '2017-12-31'
)

SELECT
    tf."trip_id"                                                AS "TRIP_ID",
    tf."duration_sec"                                           AS "DURATION_SEC",
    CAST(tf.start_ts AS DATE)                                   AS "START_DATE",
    tf."start_station_name"                                     AS "START_STATION_NAME",
    tf."start_station_name" || ' - ' || tf."end_station_name"   AS "ROUTE",
    tf."bike_number"                                            AS "BIKE_NUMBER",
    tf."subscriber_type"                                        AS "SUBSCRIBER_TYPE",
    tf."member_birth_year"                                      AS "MEMBER_BIRTH_YEAR",
    EXTRACT(YEAR FROM CURRENT_DATE) - CAST(tf."member_birth_year" AS INTEGER)                  AS "AGE",
    CASE
        WHEN EXTRACT(YEAR FROM CURRENT_DATE) - CAST(tf."member_birth_year" AS INTEGER) < 40  THEN 'Young (<40 Y.O)'
        WHEN EXTRACT(YEAR FROM CURRENT_DATE) - CAST(tf."member_birth_year" AS INTEGER) BETWEEN 40 AND 60 THEN 'Adult (40-60 Y.O)'
        ELSE 'Senior Adult (>60 Y.O)'
    END                                                        AS "AGE_CLASS",
    tf."member_gender"                                          AS "MEMBER_GENDER",
    r."name"                                                    AS "REGION_NAME"
FROM trips_filtered tf
LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO si
       ON si."station_id" = CAST(tf."start_station_id" AS TEXT)
LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_REGIONS r
       ON r."region_id" = si."region_id"
ORDER BY tf."duration_sec" DESC NULLS LAST
LIMIT 5;