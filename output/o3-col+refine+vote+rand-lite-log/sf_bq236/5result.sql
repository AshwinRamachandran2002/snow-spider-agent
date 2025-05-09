/*  Top-5 U.S. ZIP codes with the greatest number of hail-storm
    events during the most-recent 10 years (2015-2024)             */
WITH union_storms AS (   -- 1. bring together the 10 yearly Storm-Data tables
    SELECT "state_fips_code",
           "cz_fips_code",
           "event_type"
      FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2015"
    UNION ALL
    SELECT "state_fips_code", "cz_fips_code", "event_type"
      FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2016"
    UNION ALL
    SELECT "state_fips_code", "cz_fips_code", "event_type"
      FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2017"
    UNION ALL
    SELECT "state_fips_code", "cz_fips_code", "event_type"
      FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2018"
    UNION ALL
    SELECT "state_fips_code", "cz_fips_code", "event_type"
      FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2019"
    UNION ALL
    SELECT "state_fips_code", "cz_fips_code", "event_type"
      FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2020"
    UNION ALL
    SELECT "state_fips_code", "cz_fips_code", "event_type"
      FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2021"
    UNION ALL
    SELECT "state_fips_code", "cz_fips_code", "event_type"
      FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2022"
    UNION ALL
    SELECT "state_fips_code", "cz_fips_code", "event_type"
      FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2023"
    UNION ALL
    SELECT "state_fips_code", "cz_fips_code", "event_type"
      FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2024"
),
hail_events AS (         -- 2. keep only hail events and build 5-digit county FIPS
    SELECT LPAD("state_fips_code", 2, '0') || LPAD("cz_fips_code", 3, '0')
           AS "county_fips_code"
      FROM union_storms
     WHERE "event_type" ILIKE '%hail%'
),
hail_by_zip AS (         -- 3. spatially link hail counties → ZIP codes
    SELECT z."zip_code",
           COUNT(*) AS "hail_events"
      FROM hail_events                                   h
      JOIN NOAA_DATA_PLUS.GEO_US_BOUNDARIES."COUNTIES"  c
            ON c."county_fips_code" = h."county_fips_code"
      JOIN NOAA_DATA_PLUS.GEO_US_BOUNDARIES."ZIP_CODES" z
            ON ST_WITHIN(
                   TO_GEOGRAPHY(z."zip_code_geom"),
                   TO_GEOGRAPHY(c."county_geom")
               )
     GROUP BY z."zip_code"
)
-- 4. final answer: top-5 ZIP codes by hail-event count
SELECT "zip_code",
       "hail_events"
  FROM hail_by_zip
 ORDER BY "hail_events" DESC NULLS LAST
 LIMIT 5;