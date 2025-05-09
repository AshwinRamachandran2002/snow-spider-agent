WITH trips_filtered AS (
    SELECT
        t."trip_id",
        t."duration_sec",
        t."start_date",
        t."start_station_name",
        t."end_station_name",
        t."start_station_id",
        t."bike_number",
        t."subscriber_type",
        t."member_birth_year",
        /* calculate current age */
        EXTRACT(YEAR FROM CURRENT_DATE()) - t."member_birth_year"   AS "current_age",
        t."member_gender"
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE."BIKESHARE_TRIPS" t
    /* 2017-07-01 – 2017-12-31 (micro-seconds) */
    WHERE t."start_date" BETWEEN 1498867200000000 AND 1514678400000000
      AND t."start_station_name" IS NOT NULL
      AND t."member_birth_year"  IS NOT NULL
      AND t."member_gender"      IS NOT NULL
)

SELECT
    tf."trip_id",
    tf."duration_sec",
    tf."start_date",
    tf."start_station_name",
    /* build the route string */
    tf."start_station_name" || ' - ' || tf."end_station_name"     AS "route",
    tf."bike_number",
    tf."subscriber_type",
    tf."member_birth_year",
    tf."current_age",
    /* age classification */
    CASE
        WHEN tf."current_age" < 40  THEN 'Young (<40 Y.O)'
        WHEN tf."current_age" <= 60 THEN 'Adult (40-60 Y.O)'
        ELSE 'Senior Adult (>60 Y.O)'
    END                                                          AS "age_class",
    tf."member_gender",
    br."name"                                                    AS "region_name"
FROM trips_filtered tf
/* map start-station → region */
LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE."BIKESHARE_STATION_INFO" si
       ON si."station_id" = CAST(tf."start_station_id" AS TEXT)
LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE."BIKESHARE_REGIONS" br
       ON br."region_id" = si."region_id"
ORDER BY tf."duration_sec" DESC NULLS LAST
LIMIT 5;