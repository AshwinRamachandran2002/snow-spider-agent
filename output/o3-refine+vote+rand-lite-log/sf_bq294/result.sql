SELECT 
    t."trip_id",
    t."duration_sec",
    s_ts                         AS "start_date",
    t."start_station_name",
    t."start_station_name" || ' - ' || t."end_station_name" 
                                   AS "route",
    t."bike_number",
    t."subscriber_type",
    t."member_birth_year",
    (YEAR(CURRENT_DATE) - t."member_birth_year") 
                                   AS "age",
    CASE 
        WHEN (YEAR(CURRENT_DATE) - t."member_birth_year") < 40
             THEN 'Young (<40 Y.O)'
        WHEN (YEAR(CURRENT_DATE) - t."member_birth_year") BETWEEN 40 AND 60
             THEN 'Adult (40-60 Y.O)'
        ELSE 'Senior Adult (>60 Y.O)'
    END                           AS "age_class",
    t."member_gender",
    COALESCE(r."name",'Unknown')  AS "region_name"
FROM (
        SELECT 
            bt.*,
            TO_TIMESTAMP(bt."start_date"/1000000) AS s_ts
        FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS bt
     ) t
LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO si
       ON TRY_TO_NUMBER(si."station_id") = t."start_station_id"
LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_REGIONS r
       ON si."region_id" = r."region_id"
WHERE  t."start_station_name" IS NOT NULL
  AND  t."member_birth_year"  IS NOT NULL
  AND  t."member_gender"      IS NOT NULL
  AND  s_ts BETWEEN '2017-07-01'::DATE 
               AND '2017-12-31 23:59:59'::TIMESTAMP
ORDER BY t."duration_sec" DESC NULLS LAST,
         t."trip_id"
LIMIT 5;