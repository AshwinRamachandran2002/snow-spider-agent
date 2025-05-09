/*  Top-5 ZIP codes with the greatest number of hail-storm events
    recorded in Storm-Data during the last 10 calendar years
    (2014 – 2024, inclusive).                                        */

WITH hail_events AS (      ----------------------------------------------------
    /* 1.  Collect every hail row from the ten Storm-Data year tables
          and keep only the two FIPS columns that locate the county. */
    SELECT
        LPAD("state_fips_code",2,'0') || LPAD("cz_fips_code",3,'0') AS "county_fips"
    FROM (
        SELECT "state_fips_code","cz_fips_code","event_type" FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2024"
        UNION ALL
        SELECT "state_fips_code","cz_fips_code","event_type" FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2023"
        UNION ALL
        SELECT "state_fips_code","cz_fips_code","event_type" FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2022"
        UNION ALL
        SELECT "state_fips_code","cz_fips_code","event_type" FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2021"
        UNION ALL
        SELECT "state_fips_code","cz_fips_code","event_type" FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2020"
        UNION ALL
        SELECT "state_fips_code","cz_fips_code","event_type" FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2019"
        UNION ALL
        SELECT "state_fips_code","cz_fips_code","event_type" FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2018"
        UNION ALL
        SELECT "state_fips_code","cz_fips_code","event_type" FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2017"
        UNION ALL
        SELECT "state_fips_code","cz_fips_code","event_type" FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2016"
        UNION ALL
        SELECT "state_fips_code","cz_fips_code","event_type" FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2015"
        UNION ALL
        SELECT "state_fips_code","cz_fips_code","event_type" FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2014"
    ) AS unioned
    WHERE LOWER("event_type") LIKE '%hail%'
),                                                                  ----------
hail_by_county AS (
    /* 2.  Count hail events per county.  This avoids cross-duplication
          later when we multiply events by ZIP polygons.            */
    SELECT "county_fips",
           COUNT(*) AS "hail_events_cnty"
    FROM   hail_events
    GROUP  BY "county_fips"
),                                                                  ----------
zip_in_county AS (
    /* 3.  Spatial join: every ZIP whose polygon lies completely inside
          the county polygon inherits the county’s hail-event count. */
    SELECT
        z."zip_code",
        h."hail_events_cnty"
    FROM   hail_by_county               h
    JOIN   NOAA_DATA_PLUS.GEO_US_BOUNDARIES."COUNTIES"  c
           ON h."county_fips" = c."county_fips_code"
    JOIN   NOAA_DATA_PLUS.GEO_US_BOUNDARIES."ZIP_CODES" z
           ON ST_WITHIN(
                 TO_GEOGRAPHY(z."zip_code_geom"),
                 TO_GEOGRAPHY(c."county_geom")
              )
)                                                                   ----------
/* 4.  Aggregate to ZIP level and return the five highest values.  */
SELECT
       "zip_code",
       SUM("hail_events_cnty") AS "hail_events_last_10yrs"
FROM   zip_in_county
GROUP  BY "zip_code"
ORDER  BY "hail_events_last_10yrs" DESC NULLS LAST,
          "zip_code"                ASC
LIMIT  5;