SELECT
    t."trip_id"                                            AS "trip_id",
    t."duration_sec"                                       AS "duration_sec",
    TO_TIMESTAMP_NTZ(t."start_date" / 1000000)             AS "start_date",
    t."start_station_name"                                 AS "start_station_name",
    CONCAT(t."start_station_name", ' - ', t."end_station_name") 
                                                          AS "route",
    t."bike_number"                                        AS "bike_number",
    t."subscriber_type"                                    AS "subscriber_type",
    CAST(t."member_birth_year" AS INTEGER)                 AS "member_birth_year",
    YEAR(CURRENT_DATE) - CAST(t."member_birth_year" AS INTEGER) 
                                                          AS "age",
    CASE 
        WHEN YEAR(CURRENT_DATE) - CAST(t."member_birth_year" AS INTEGER) < 40 
             THEN 'Young (<40 Y.O)'
        WHEN YEAR(CURRENT_DATE) - CAST(t."member_birth_year" AS INTEGER) BETWEEN 40 AND 60 
             THEN 'Adult (40-60 Y.O)'
        ELSE 'Senior Adult (>60 Y.O)'
    END                                                    AS "age_classification",
    t."member_gender"                                      AS "member_gender",
    COALESCE(r."name", 'Unknown')                          AS "region_name"
FROM   "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_BIKESHARE"."BIKESHARE_TRIPS"            t
LEFT  JOIN "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_BIKESHARE"."BIKESHARE_STATION_INFO" si
       ON si."station_id" = TO_VARCHAR(t."start_station_id")
LEFT  JOIN "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_BIKESHARE"."BIKESHARE_REGIONS"      r
       ON r."region_id" = si."region_id"
WHERE  t."start_station_name" IS NOT NULL
  AND  t."member_birth_year" IS NOT NULL
  AND  t."member_gender" IS NOT NULL
  AND  TO_DATE(TO_TIMESTAMP_NTZ(t."start_date" / 1000000)) 
           BETWEEN '2017-07-01' AND '2017-12-31'
ORDER BY t."duration_sec" DESC NULLS LAST
FETCH FIRST 5 ROWS;