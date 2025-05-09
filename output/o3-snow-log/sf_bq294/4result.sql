WITH trips_filtered AS (
    SELECT
        t."trip_id",
        t."duration_sec",
        TO_TIMESTAMP(t."start_date" / 1000000)                                     AS "start_date",
        t."start_station_name",
        t."end_station_name",
        t."bike_number",
        t."subscriber_type",
        t."member_birth_year",
        t."member_gender",
        t."start_station_id"
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS t
    WHERE
          t."start_station_name" IS NOT NULL
      AND t."member_birth_year"   IS NOT NULL
      AND t."member_gender"       IS NOT NULL
      AND TO_TIMESTAMP(t."start_date" / 1000000)
            BETWEEN '2017-07-01' AND '2017-12-31 23:59:59'
),
age_calc AS (
    SELECT
        tf.*,
        (YEAR(CURRENT_DATE()) - tf."member_birth_year")                           AS "age",
        CASE
            WHEN (YEAR(CURRENT_DATE()) - tf."member_birth_year") < 40  THEN 'Young (<40 Y.O)'
            WHEN (YEAR(CURRENT_DATE()) - tf."member_birth_year") BETWEEN 40 AND 60 THEN 'Adult (40-60 Y.O)'
            ELSE 'Senior Adult (>60 Y.O)'
        END                                                                       AS "age_class"
    FROM trips_filtered tf
),
region_join AS (
    SELECT
        ac.*,
        r."name"                                                                  AS "region_name"
    FROM age_calc ac
    LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO si
           ON si."station_id" = TO_CHAR(ac."start_station_id")
    LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_REGIONS r
           ON r."region_id" = si."region_id"
)
SELECT
    "trip_id",
    "duration_sec",
    "start_date",
    "start_station_name",
    CONCAT("start_station_name", ' - ', "end_station_name")                       AS "route",
    "bike_number",
    "subscriber_type",
    "member_birth_year",
    "age",
    "age_class",
    "member_gender",
    COALESCE("region_name", 'Unknown')                                            AS "region_name"
FROM region_join
ORDER BY "duration_sec" DESC NULLS LAST
LIMIT 5;