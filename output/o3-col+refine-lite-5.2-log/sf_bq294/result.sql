WITH qualified_trips AS (
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
        t."member_gender",
        /* current age */
        DATE_PART('year', CURRENT_DATE) - t."member_birth_year"            AS "age_now"
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS t
    WHERE t."start_date" BETWEEN 1498867200000000      /* 2017‑07‑01 00:00:00 */
                          AND     1514764799000000     /* 2017‑12‑31 23:59:59 */
      AND t."start_station_name" IS NOT NULL
      AND t."member_birth_year"  IS NOT NULL
      AND t."member_gender"      IS NOT NULL
)

SELECT
    qt."trip_id",
    qt."duration_sec",
    qt."start_date",
    qt."start_station_name",
    qt."start_station_name" || ' - ' || qt."end_station_name"  AS "route",
    qt."bike_number",
    qt."subscriber_type",
    qt."member_birth_year",
    qt."age_now",
    CASE
        WHEN qt."age_now" < 40                 THEN 'Young (<40 Y.O)'
        WHEN qt."age_now" BETWEEN 40 AND 60    THEN 'Adult (40-60 Y.O)'
        ELSE                                         'Senior Adult (>60 Y.O)'
    END                                                       AS "age_class",
    qt."member_gender",
    r."name"                                                  AS "region_name"
FROM qualified_trips qt
LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO si
       ON TRY_TO_NUMBER(si."station_id") = qt."start_station_id"
LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_REGIONS r
       ON si."region_id" = r."region_id"
ORDER BY qt."duration_sec" DESC NULLS LAST, qt."trip_id"
LIMIT 5;