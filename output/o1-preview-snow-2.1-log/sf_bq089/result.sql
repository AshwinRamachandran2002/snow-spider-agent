SELECT
    c."facility_sub_region_2" AS "county_name",
    ROUND(
        (COUNT(DISTINCT c."facility_provider_id") / p."total_pop") * 1000,
        4
    ) AS "number_of_vaccine_sites_per_1000_people"
FROM
    "COVID19_USA"."COVID19_VACCINATION_ACCESS"."FACILITY_BOUNDARY_US_ALL" AS c
JOIN (
    SELECT
        LPAD(CAST("geo_id" AS TEXT), 5, '0') AS "county_fips_code",
        "total_pop"
    FROM
        "COVID19_USA"."CENSUS_BUREAU_ACS"."COUNTY_2018_5YR"
    WHERE LEFT(LPAD(CAST("geo_id" AS TEXT), 5, '0'), 2) = '06'  -- California State FIPS code is '06'
) AS p
ON LPAD(c."facility_sub_region_2_code", 5, '0') = p."county_fips_code"
WHERE c."facility_sub_region_1" = 'California'
GROUP BY
    c."facility_sub_region_2",
    p."total_pop"
ORDER BY
    c."facility_sub_region_2";