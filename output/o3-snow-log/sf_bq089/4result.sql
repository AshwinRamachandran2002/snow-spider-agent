WITH pop AS (
    SELECT
        SUBSTR("geo_id", 1, 5)       AS county_fips,
        SUM("total_pop")             AS county_pop
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."BLOCKGROUP_2018_5YR"
    WHERE "geo_id" LIKE '06%'               -- California state code
    GROUP BY SUBSTR("geo_id", 1, 5)
),
sites AS (
    SELECT
        "facility_sub_region_2_code" AS county_fips,
        COUNT(DISTINCT "facility_name") AS total_sites
    FROM (
            SELECT "facility_sub_region_2_code", "facility_name"
            FROM COVID19_USA.COVID19_VACCINATION_ACCESS."FACILITY_BOUNDARY_US_ALL"
            UNION ALL
            SELECT "facility_sub_region_2_code", "facility_name"
            FROM COVID19_USA.COVID19_VACCINATION_ACCESS."FACILITY_BOUNDARY_US_DRIVE"
            UNION ALL
            SELECT "facility_sub_region_2_code", "facility_name"
            FROM COVID19_USA.COVID19_VACCINATION_ACCESS."FACILITY_BOUNDARY_US_TRANSIT"
            UNION ALL
            SELECT "facility_sub_region_2_code", "facility_name"
            FROM COVID19_USA.COVID19_VACCINATION_ACCESS."FACILITY_BOUNDARY_US_WALK"
         )
    WHERE "facility_sub_region_2_code" IS NOT NULL
      AND "facility_sub_region_2_code" LIKE '06%'   -- California counties
    GROUP BY "facility_sub_region_2_code"
)
SELECT
       pop.county_fips,
       pop.county_pop,
       sites.total_sites,
       ROUND(sites.total_sites / (pop.county_pop / 1000.0), 4) AS sites_per_1000
FROM   pop
JOIN   sites
       ON pop.county_fips = sites.county_fips
ORDER  BY sites_per_1000 DESC NULLS LAST;