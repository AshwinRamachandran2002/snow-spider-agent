-- Top-5 U.S. ZIP codes with the highest number of hail-storm events
-- recorded during the last 10 complete calendar years (2014-2023)

WITH hail_events_last_10yrs AS (   -- 1)  gather all hail rows 2014-2023
    SELECT "cz_fips_code"
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2014" WHERE LOWER("event_type")='hail'
    UNION ALL
    SELECT "cz_fips_code"
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2015" WHERE LOWER("event_type")='hail'
    UNION ALL
    SELECT "cz_fips_code"
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2016" WHERE LOWER("event_type")='hail'
    UNION ALL
    SELECT "cz_fips_code"
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2017" WHERE LOWER("event_type")='hail'
    UNION ALL
    SELECT "cz_fips_code"
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2018" WHERE LOWER("event_type")='hail'
    UNION ALL
    SELECT "cz_fips_code"
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2019" WHERE LOWER("event_type")='hail'
    UNION ALL
    SELECT "cz_fips_code"
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2020" WHERE LOWER("event_type")='hail'
    UNION ALL
    SELECT "cz_fips_code"
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2021" WHERE LOWER("event_type")='hail'
    UNION ALL
    SELECT "cz_fips_code"
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2022" WHERE LOWER("event_type")='hail'
    UNION ALL
    SELECT "cz_fips_code"
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2023" WHERE LOWER("event_type")='hail'
),
hail_counts_by_cz AS (             -- 2)  hail counts per CZ-FIPS (county code inside state)
    SELECT
        TRIM("cz_fips_code") AS "cz_fips_code",
        COUNT(*)            AS "hail_events"
    FROM hail_events_last_10yrs
    WHERE "cz_fips_code" IS NOT NULL
      AND "cz_fips_code" <> '0'
    GROUP BY TRIM("cz_fips_code")
),
county_with_hail AS (              -- 3)  attach hail counts to full county polygons
    SELECT
        c."county_fips_code",
        TO_GEOMETRY(c."county_geom")        AS "county_geom",
        h."hail_events"
    FROM NOAA_DATA_PLUS.GEO_US_BOUNDARIES."COUNTIES"  c
    JOIN hail_counts_by_cz                      h
      ON RIGHT(c."county_fips_code", LENGTH(h."cz_fips_code")) = h."cz_fips_code"
),
zip_hail AS (                       -- 4)  spatially assign those hail counts to ZIP polygons
    SELECT
        z."zip_code",
        SUM(c."hail_events") AS "hail_events"
    FROM NOAA_DATA_PLUS.GEO_US_BOUNDARIES."ZIP_CODES" z
    JOIN county_with_hail                c
      ON ST_WITHIN( TO_GEOMETRY(z."zip_code_geom"), c."county_geom" )
    GROUP BY z."zip_code"
)
SELECT
    "zip_code",
    "hail_events"
FROM zip_hail
ORDER BY "hail_events" DESC NULLS LAST
LIMIT 5;