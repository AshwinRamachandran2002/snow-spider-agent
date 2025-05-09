SELECT
    t."trip_id"                               AS "TRIP_ID",
    t."duration_sec"                          AS "DURATION_SEC",
    DATE(start_ts)                            AS "START_DATE",
    t."start_station_name"                    AS "START_STATION_NAME",
    t."start_station_name" || ' - ' || t."end_station_name"    
                                              AS "ROUTE",
    t."bike_number"                           AS "BIKE_NUMBER",
    t."subscriber_type"                       AS "SUBSCRIBER_TYPE",
    t."member_birth_year"                     AS "MEMBER_BIRTH_YEAR",
    age                                       AS "AGE",
    CASE 
        WHEN age < 40  THEN 'Young (<40 Y.O)'
        WHEN age <= 60 THEN 'Adult (40-60 Y.O)'
        ELSE               'Senior Adult (>60 Y.O)'
    END                                        AS "AGE_CLASS",
    t."member_gender"                         AS "MEMBER_GENDER",
    r."name"                                  AS "REGION_NAME"
FROM (
        SELECT  *,
                TO_TIMESTAMP_NTZ("start_date" / 1000000)                      AS start_ts,
                (YEAR(CURRENT_DATE) - "member_birth_year")                    AS age
        FROM    SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS
) t
LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO s
       ON CAST(t."start_station_id" AS STRING) = s."station_id"
LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_REGIONS     r
       ON s."region_id" = r."region_id"
WHERE   DATE(start_ts) BETWEEN '2017-07-01' AND '2017-12-31'
    AND t."start_station_name"  IS NOT NULL
    AND t."member_birth_year"   IS NOT NULL
    AND t."member_gender"       IS NOT NULL
ORDER BY 
    t."duration_sec" DESC NULLS LAST,
    t."trip_id"
LIMIT 5;