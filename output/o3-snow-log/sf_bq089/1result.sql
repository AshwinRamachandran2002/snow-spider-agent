/*  Vaccine-site density (sites per 1,000 residents) for every California county  */
WITH pop AS (   /* 2018 5-year ACS population by county (FIPS = first 5 digits of GEOID) */
    SELECT
        SUBSTR("geo_id", 1, 5)                 AS "county_fips",
        SUM("total_pop")                       AS "county_pop_2018"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR
    WHERE "geo_id" ILIKE '06%'                -- California GEOIDs start with 06
    GROUP BY SUBSTR("geo_id", 1, 5)
),
sites AS (      /* Vaccination-site counts by county */
    SELECT
        "facility_sub_region_2_code"           AS "county_fips",
        MIN("facility_sub_region_2")           AS "county_name",   -- e.g., “Los Angeles County”
        COUNT(*)                               AS "site_cnt"
    FROM COVID19_USA.COVID19_VACCINATION_ACCESS.FACILITY_BOUNDARY_US_ALL
    WHERE "facility_sub_region_1" = 'California'
    GROUP BY "facility_sub_region_2_code"
)
SELECT
    s."county_name",
    p."county_fips",
    p."county_pop_2018",
    s."site_cnt",
    (s."site_cnt" * 1000.0) / p."county_pop_2018"  AS "sites_per_1000"
FROM pop p
JOIN sites s
  ON p."county_fips" = s."county_fips"
ORDER BY "sites_per_1000" DESC NULLS LAST;