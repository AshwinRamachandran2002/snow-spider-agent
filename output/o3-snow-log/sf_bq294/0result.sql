WITH trips_filtered AS (
    SELECT
        t."trip_id",
        t."duration_sec",
        TO_DATE(TO_TIMESTAMP_LTZ(t."start_date" / 1000000))                AS "start_date",
        t."start_station_name",
        t."end_station_name",
        t."bike_number",
        t."subscriber_type",
        t."member_birth_year",
        t."member_gender"
    FROM  SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS  t
    WHERE  t."start_station_name" IS NOT NULL
      AND  t."member_birth_year"  IS NOT NULL
      AND  t."member_gender"      IS NOT NULL
      AND  TO_DATE(TO_TIMESTAMP_LTZ(t."start_date" / 1000000))
           BETWEEN '2017-07-01' AND '2017-12-31'
)
SELECT
    tf."trip_id",
    tf."duration_sec",
    tf."start_date",
    tf."start_station_name",
    tf."start_station_name" || ' - ' || tf."end_station_name"     AS "route",
    tf."bike_number",
    tf."subscriber_type",
    CAST(tf."member_birth_year" AS INT)                           AS "member_birth_year",
    EXTRACT(year FROM CURRENT_DATE()) - CAST(tf."member_birth_year" AS INT)  AS "current_age",
    CASE
        WHEN EXTRACT(year FROM CURRENT_DATE()) - CAST(tf."member_birth_year" AS INT) < 40
             THEN 'Young (<40 Y.O)'
        WHEN EXTRACT(year FROM CURRENT_DATE()) - CAST(tf."member_birth_year" AS INT) <= 60
             THEN 'Adult (40-60 Y.O)'
        ELSE 'Senior Adult (>60 Y.O)'
    END                                                          AS "age_classification",
    tf."member_gender",
    COALESCE(r."name", 'Unknown')                                 AS "region_name"
FROM   trips_filtered tf
LEFT  JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO  si
       ON TRIM(si."name") = TRIM(tf."start_station_name")
LEFT  JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_REGIONS       r
       ON si."region_id" = r."region_id"
ORDER BY tf."duration_sec" DESC NULLS LAST
LIMIT 5;