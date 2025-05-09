SELECT
    "region_name",
    "trip_id",
    "duration_sec",
    "start_date",
    "start_station_name",
    "member_gender"
FROM (
    SELECT
        r."name" AS "region_name",
        t."trip_id",
        t."duration_sec",
        t."start_date",
        t."start_station_name",
        t."member_gender",
        ROW_NUMBER() OVER (PARTITION BY r."name" ORDER BY t."start_date" DESC NULLS LAST) AS "rn"
    FROM
        "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_BIKESHARE"."BIKESHARE_TRIPS" t
    INNER JOIN
        "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_BIKESHARE"."BIKESHARE_STATION_INFO" s
    ON
        CAST(t."start_station_id" AS VARCHAR) = s."station_id"
    INNER JOIN
        "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_BIKESHARE"."BIKESHARE_REGIONS" r
    ON
        s."region_id" = r."region_id"
    WHERE
        t."start_date" BETWEEN 1388534400000000 AND 1514764799000000
) sub
WHERE "rn" = 1;