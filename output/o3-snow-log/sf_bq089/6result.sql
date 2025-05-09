/*  Vaccine-site density (sites per 1,000 residents) for every California county  */

WITH county_pop AS (   -- 2018 ACS 5-year population
    SELECT
        SUBSTR("geo_id",1,5)                    AS "county_fips",
        SUM("total_pop")                        AS "county_pop_2018"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR
    WHERE SUBSTR("geo_id",1,2) = '06'           -- state FIPS “06” = California
    GROUP BY 1
),

facility_cnt AS (      -- distinct vaccination sites per county, by file
    /* master “ALL” boundary file */
    SELECT
        "facility_sub_region_2_code"            AS "county_fips",
        COUNT(DISTINCT "facility_name")         AS "facilities"
    FROM COVID19_USA.COVID19_VACCINATION_ACCESS.FACILITY_BOUNDARY_US_ALL
    WHERE "facility_sub_region_1" = 'California'
      AND "facility_sub_region_2_code" IS NOT NULL
    GROUP BY 1
    
    UNION ALL
    
    /* “WALK” travel-mode file (also has county FIPS codes) */
    SELECT
        "facility_sub_region_2_code"            AS "county_fips",
        COUNT(DISTINCT "facility_name")         AS "facilities"
    FROM COVID19_USA.COVID19_VACCINATION_ACCESS.FACILITY_BOUNDARY_US_WALK
    WHERE "facility_sub_region_1" = 'California'
      AND "facility_sub_region_2_code" IS NOT NULL
    GROUP BY 1
),

facility_tot AS (      -- total unique sites per county
    SELECT
        "county_fips",
        SUM("facilities")                       AS "total_facilities"
    FROM facility_cnt
    GROUP BY 1
)

SELECT
    cp."county_fips",
    cp."county_pop_2018",
    ft."total_facilities",
    ROUND( ft."total_facilities" / (cp."county_pop_2018" / 1000), 4 ) AS "sites_per_1000"
FROM county_pop  cp
JOIN facility_tot ft
  ON cp."county_fips" = ft."county_fips"
ORDER BY "sites_per_1000" DESC NULLS LAST;