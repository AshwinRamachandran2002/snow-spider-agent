/*  Vaccine sites per 1,000 residents — California counties  */

/* 1. 2018 ACS population, summed from block-groups to county FIPS (first 5 digits) */
WITH county_pop AS (
    SELECT  SUBSTRING("geo_id", 1, 5)        AS "county_fips",
            SUM("total_pop")                 AS "county_pop_2018"
    FROM    CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR
    WHERE   "geo_id" LIKE '06%'              -- California only
    GROUP BY SUBSTRING("geo_id", 1, 5)
),

/* 2. Vaccination facilities that carry county FIPS codes                       */
/*    (tables _ALL and _WALK both include facility_sub_region_2_code)            */
vacc_sites AS (
    SELECT DISTINCT
           "facility_sub_region_2_code"      AS "county_fips",
           "facility_name"
    FROM   COVID19_USA.COVID19_VACCINATION_ACCESS.FACILITY_BOUNDARY_US_ALL
    WHERE  "facility_sub_region_1" = 'California'

    UNION

    SELECT DISTINCT
           "facility_sub_region_2_code"      AS "county_fips",
           "facility_name"
    FROM   COVID19_USA.COVID19_VACCINATION_ACCESS.FACILITY_BOUNDARY_US_WALK
    WHERE  "facility_sub_region_1" = 'California'
),

/* 3. Count unique facility names per county FIPS                                 */
site_counts AS (
    SELECT  "county_fips",
            COUNT(DISTINCT "facility_name")  AS "site_cnt"
    FROM    vacc_sites
    WHERE   "county_fips" IS NOT NULL
    GROUP BY "county_fips"
)

/* 4. Combine population with site counts and compute sites per 1,000 residents   */
SELECT  p."county_fips",
        p."county_pop_2018",
        COALESCE(s."site_cnt", 0)                           AS "vaccine_sites",
        ROUND( COALESCE(s."site_cnt", 0)
               / p."county_pop_2018" * 1000, 4)             AS "sites_per_1000_pop"
FROM    county_pop  p
LEFT JOIN site_counts s
       ON p."county_fips" = s."county_fips"
ORDER BY "sites_per_1000_pop" DESC NULLS LAST;