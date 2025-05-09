WITH trips_filtered AS (
    SELECT
        t."trip_id",
        t."duration_sec",
        TO_TIMESTAMP_NTZ(t."start_date" / 1000000)          AS "start_datetime",
        t."start_station_name",
        t."end_station_name",
        t."bike_number",
        t."subscriber_type",
        t."member_birth_year",
        t."member_gender",
        TO_CHAR(t."start_station_id")                       AS "start_station_id_text"
    FROM
        SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS t
    WHERE
        TO_DATE(TO_TIMESTAMP_NTZ(t."start_date" / 1000000)) BETWEEN '2017-07-01' AND '2017-12-31'
        AND t."start_station_name" IS NOT NULL
        AND t."member_birth_year"   IS NOT NULL
        AND t."member_gender"       IS NOT NULL
)

SELECT
    tf."trip_id"                                                                    AS "trip_id",
    tf."duration_sec"                                                               AS "duration_sec",
    tf."start_datetime"                                                             AS "start_date",
    tf."start_station_name"                                                         AS "start_station_name",
    tf."start_station_name" || ' - ' || tf."end_station_name"                       AS "route",
    tf."bike_number"                                                                AS "bike_number",
    tf."subscriber_type"                                                            AS "subscriber_type",
    tf."member_birth_year"                                                          AS "member_birth_year",
    (DATE_PART('year', CURRENT_DATE()) - tf."member_birth_year")                    AS "age",
    CASE
         WHEN (DATE_PART('year', CURRENT_DATE()) - tf."member_birth_year") < 40  THEN 'Young (<40 Y.O)'
         WHEN (DATE_PART('year', CURRENT_DATE()) - tf."member_birth_year") BETWEEN 40 AND 60 THEN 'Adult (40-60 Y.O)'
         ELSE 'Senior Adult (>60 Y.O)'
    END                                                                              AS "age_class",
    tf."member_gender"                                                              AS "member_gender",
    r."name"                                                                        AS "region_name"
FROM
    trips_filtered tf
LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO si
       ON si."station_id" = tf."start_station_id_text"
LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_REGIONS     r
       ON r."region_id" = si."region_id"
ORDER BY
    tf."duration_sec" DESC NULLS LAST
LIMIT 5;