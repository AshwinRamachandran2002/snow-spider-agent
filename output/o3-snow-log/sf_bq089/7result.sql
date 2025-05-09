WITH pop AS (
    SELECT 
        SUBSTR("geo_id", 1, 5)         AS "county_fips",
        SUM("total_pop")               AS "county_population_2018"
    FROM
        CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR
    WHERE
        "geo_id" LIKE '06%'            -- California state FIPS codes start with 06
    GROUP BY
        SUBSTR("geo_id", 1, 5)
),
sites AS (
    SELECT
        "facility_sub_region_2_code"   AS "county_fips",
        COUNT(*)                       AS "vaccination_sites"
    FROM
        COVID19_USA.COVID19_VACCINATION_ACCESS.FACILITY_BOUNDARY_US_ALL
    WHERE
        "facility_sub_region_1" = 'California'
    GROUP BY
        "facility_sub_region_2_code"
)
SELECT
    s."county_fips",
    p."county_population_2018",
    s."vaccination_sites",
    ROUND(s."vaccination_sites" / p."county_population_2018" * 1000, 4) AS "sites_per_1000_pop"
FROM
    sites s
JOIN 
    pop p USING ("county_fips")
ORDER BY
    "sites_per_1000_pop" DESC NULLS LAST;