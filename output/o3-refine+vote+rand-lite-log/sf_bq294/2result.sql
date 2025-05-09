SELECT
    t."trip_id",
    t."duration_sec",
    /* convert micro‑seconds since epoch to timestamp */
    TO_TIMESTAMP_NTZ(t."start_date" / 1000000)          AS "start_timestamp",
    t."start_station_name",
    /* route = start station - end station */
    t."start_station_name" || ' - ' || t."end_station_name" AS "route",
    t."bike_number",
    t."subscriber_type",
    t."member_birth_year",
    /* current age */
    YEAR(CURRENT_DATE()) - t."member_birth_year"        AS "age",
    /* age class */
    CASE
        WHEN YEAR(CURRENT_DATE()) - t."member_birth_year" < 40  THEN 'Young (<40 Y.O)'
        WHEN YEAR(CURRENT_DATE()) - t."member_birth_year" <= 60 THEN 'Adult (40-60 Y.O)'
        ELSE 'Senior Adult (>60 Y.O)'
    END                                                AS "age_class",
    t."member_gender",
    COALESCE(r."name", 'Unknown')                      AS "region_name"
FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS t
/* join start station to look up its region, then to region table */
LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO si
       ON si."station_id" = TO_VARCHAR(t."start_station_id")
LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_REGIONS r
       ON r."region_id" = si."region_id"
/* filter for requested period & required non‑null fields */
WHERE
      /* July 1 – Dec 31 2017 inclusive */
      TO_TIMESTAMP_NTZ(t."start_date" / 1000000)
          BETWEEN '2017-07-01' AND '2017-12-31 23:59:59'
  AND t."start_station_name" IS NOT NULL
  AND t."member_birth_year"  IS NOT NULL
  AND t."member_gender"      IS NOT NULL
/* get the 5 longest trips */
ORDER BY t."duration_sec" DESC NULLS LAST
LIMIT 5;