SELECT
    BT."trip_id",
    BT."duration_sec",
    TO_TIMESTAMP(BT."start_date" / 1000000)                          AS "start_date",
    BT."start_station_name",
    BT."start_station_name" || ' - ' || BT."end_station_name"        AS "route",
    BT."bike_number",
    BT."subscriber_type",
    CAST(BT."member_birth_year" AS INT)                              AS "member_birth_year",
    (YEAR(CURRENT_DATE) - CAST(BT."member_birth_year" AS INT))       AS "current_age",
    CASE
        WHEN (YEAR(CURRENT_DATE) - CAST(BT."member_birth_year" AS INT)) < 40
             THEN 'Young (<40 Y.O)'
        WHEN (YEAR(CURRENT_DATE) - CAST(BT."member_birth_year" AS INT)) BETWEEN 40 AND 60
             THEN 'Adult (40-60 Y.O)'
        ELSE 'Senior Adult (>60 Y.O)'
    END                                                              AS "age_class",
    BT."member_gender",
    COALESCE(R."name", 'Unknown')                                    AS "region_name"
FROM  SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS          BT
LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO SI
       ON SI."station_id" = CAST(BT."start_station_id" AS TEXT)
LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_REGIONS      R
       ON R."region_id" = SI."region_id"
WHERE
      TO_DATE(TO_TIMESTAMP(BT."start_date" / 1000000)) BETWEEN '2017-07-01' AND '2017-12-31'
  AND BT."start_station_name" IS NOT NULL
  AND BT."member_birth_year"  IS NOT NULL
  AND BT."member_birth_year"  = BT."member_birth_year"               -- remove NaN
  AND BT."member_gender"      IS NOT NULL
ORDER BY BT."duration_sec" DESC NULLS LAST, BT."trip_id"
LIMIT 5;