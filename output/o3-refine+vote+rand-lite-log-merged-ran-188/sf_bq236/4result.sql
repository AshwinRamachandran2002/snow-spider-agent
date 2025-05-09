WITH hail_events AS (
    /* 10-year hail-storm records (2015-2024) */
    SELECT LPAD("cz_fips_code",3,'0') AS county_code_3
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2015"
    WHERE "event_type" ILIKE '%hail%'
    UNION ALL
    SELECT LPAD("cz_fips_code",3,'0') FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2016" WHERE "event_type" ILIKE '%hail%'
    UNION ALL
    SELECT LPAD("cz_fips_code",3,'0') FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2017" WHERE "event_type" ILIKE '%hail%'
    UNION ALL
    SELECT LPAD("cz_fips_code",3,'0') FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2018" WHERE "event_type" ILIKE '%hail%'
    UNION ALL
    SELECT LPAD("cz_fips_code",3,'0') FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2019" WHERE "event_type" ILIKE '%hail%'
    UNION ALL
    SELECT LPAD("cz_fips_code",3,'0') FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2020" WHERE "event_type" ILIKE '%hail%'
    UNION ALL
    SELECT LPAD("cz_fips_code",3,'0') FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2021" WHERE "event_type" ILIKE '%hail%'
    UNION ALL
    SELECT LPAD("cz_fips_code",3,'0') FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2022" WHERE "event_type" ILIKE '%hail%'
    UNION ALL
    SELECT LPAD("cz_fips_code",3,'0') FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2023" WHERE "event_type" ILIKE '%hail%'
    UNION ALL
    SELECT LPAD("cz_fips_code",3,'0') FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2024" WHERE "event_type" ILIKE '%hail%'
),
hail_by_county AS (
    /* hail totals per 3-digit county code */
    SELECT county_code_3,
           COUNT(*) AS hail_events_10yr
    FROM   hail_events
    WHERE  county_code_3 <> '000'            -- ignore missing county codes
    GROUP  BY county_code_3
),
zip_with_county AS (
    /* map zip polygons to the county that fully contains them */
    SELECT z."zip_code",
           RIGHT(c."county_fips_code",3) AS county_code_3
    FROM   NOAA_DATA_PLUS.GEO_US_BOUNDARIES."ZIP_CODES"  z
    JOIN   NOAA_DATA_PLUS.GEO_US_BOUNDARIES."COUNTIES"   c
           ON ST_WITHIN(
                  TO_GEOGRAPHY(z."zip_code_geom"),
                  TO_GEOGRAPHY(c."county_geom")
              )
)
/* aggregate hail counts to each zip code and rank */
SELECT  z."zip_code",
        SUM(h.hail_events_10yr) AS "hail_events_10yr"
FROM    zip_with_county z
JOIN    hail_by_county  h
        ON z.county_code_3 = h.county_code_3
GROUP BY z."zip_code"
ORDER BY "hail_events_10yr" DESC NULLS LAST
LIMIT 5;