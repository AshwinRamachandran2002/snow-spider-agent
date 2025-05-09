WITH county_pop AS (
    -- 2018 ACS 5-year population summed to the county (first 5 digits of block-group GEOID)
    SELECT 
        SUBSTR("geo_id", 1, 5)                            AS "county_fips",
        SUM("total_pop")                                  AS "county_pop_2018"
    FROM   CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR
    WHERE  "geo_id" LIKE '06%'                           -- California only
    GROUP  BY 1
),
vax_sites AS (
    -- count distinct vaccination facilities in each California county
    SELECT
        "facility_sub_region_2_code"                      AS "county_fips",
        COUNT(DISTINCT "facility_name")                   AS "facility_sites"
    FROM   COVID19_USA.COVID19_VACCINATION_ACCESS.FACILITY_BOUNDARY_US_ALL
    WHERE  "facility_sub_region_1" = 'California'
    GROUP  BY 1
)
SELECT
    p."county_fips",
    p."county_pop_2018",
    COALESCE(v."facility_sites", 0)                       AS "facility_sites",
    ROUND( COALESCE(v."facility_sites", 0) 
           / p."county_pop_2018" * 1000 , 4)              AS "sites_per_1000"
FROM   county_pop p
LEFT   JOIN vax_sites v
       ON p."county_fips" = v."county_fips"
ORDER  BY "sites_per_1000" DESC NULLS LAST;