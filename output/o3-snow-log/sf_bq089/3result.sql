/*  Vaccine-site density (sites per 1,000 residents) for every California county  */

WITH county_pop AS (   -- 2018 ACS 5-year population, aggregated to county FIPS
    SELECT SUBSTR("geo_id",1,5)            AS "county_fips",
           SUM("total_pop")                AS "population_2018"
    FROM   CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."BLOCKGROUP_2018_5YR"
    WHERE  "geo_id" ILIKE '06%'            -- “06” = California
    GROUP  BY 1
),

all_sites AS (        -- collect county FIPS for *every* vaccination-site record
    SELECT "facility_sub_region_2_code"    AS "county_fips"
    FROM   COVID19_USA.COVID19_VACCINATION_ACCESS."FACILITY_BOUNDARY_US_ALL"
    WHERE  "facility_sub_region_1" = 'California'
    
    UNION ALL
    
    SELECT "facility_sub_region_2_code"    AS "county_fips"
    FROM   COVID19_USA.COVID19_VACCINATION_ACCESS."FACILITY_BOUNDARY_US_WALK"
    WHERE  "facility_sub_region_1" = 'California'
    
    UNION ALL
    
    SELECT "facility_sub_region_2_code"    AS "county_fips"
    FROM   COVID19_USA.COVID19_VACCINATION_ACCESS."FACILITY_BOUNDARY_US_DRIVE"
    WHERE  "facility_sub_region_1" = 'California'
    
    UNION ALL
    
    /*  In the TRANSIT table the FIPS is stored in facility_sub_region_2  */
    SELECT "facility_sub_region_2"         AS "county_fips"
    FROM   COVID19_USA.COVID19_VACCINATION_ACCESS."FACILITY_BOUNDARY_US_TRANSIT"
    WHERE  "facility_sub_region_1" = 'California'
),

site_counts AS (      -- total (not deduplicated) site rows per county
    SELECT "county_fips",
           COUNT(*)                       AS "site_total"
    FROM   all_sites
    GROUP  BY 1
)

SELECT p."county_fips",
       p."population_2018",
       s."site_total",
       ROUND( (s."site_total" / p."population_2018") * 1000 , 4)  AS "sites_per_1000"
FROM   county_pop  p
LEFT   JOIN site_counts s
       ON p."county_fips" = s."county_fips"
ORDER  BY "sites_per_1000" DESC NULLS LAST;