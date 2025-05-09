WITH county_pop AS (
    /* 2018 5-year ACS total population aggregated to the county FIPS (state+county = first 5 chars) */
    SELECT 
        LEFT("geo_id", 5)                       AS "county_fips",
        SUM("total_pop")                        AS "county_pop_2018_5yr"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR
    WHERE "geo_id" LIKE '06%'                  -- California state FIPS = 06
    GROUP BY LEFT("geo_id", 5)
),
site_cnt AS (
    /* count of vaccination facilities by county FIPS, plus a readable county name */
    SELECT
        "facility_sub_region_2_code"            AS "county_fips",
        MAX("facility_sub_region_2")            AS "county_name",
        COUNT(*)                                AS "vaccine_sites"
    FROM COVID19_USA.COVID19_VACCINATION_ACCESS.FACILITY_BOUNDARY_US_ALL
    WHERE "facility_sub_region_1" = 'California'
    GROUP BY "facility_sub_region_2_code"
)
SELECT
    s."county_name",
    p."county_pop_2018_5yr",
    s."vaccine_sites",
    ROUND( (s."vaccine_sites" / NULLIF(p."county_pop_2018_5yr", 0)) * 1000, 4) AS "sites_per_1000_pop"
FROM county_pop p
JOIN site_cnt  s USING ("county_fips")
ORDER BY "sites_per_1000_pop" DESC NULLS LAST;