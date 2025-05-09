SELECT
    v."county_name",
    ROUND((v."vaccine_site_count" * 1000.0) / p."total_pop", 4) AS "number_of_vaccine_sites_per_1000_people"
FROM
    (
        SELECT 
            "facility_sub_region_2_code" AS "county_fips",
            "facility_sub_region_2" AS "county_name",
            COUNT(*) AS "vaccine_site_count"
        FROM
            "COVID19_USA"."COVID19_VACCINATION_ACCESS"."FACILITY_BOUNDARY_US_ALL"
        WHERE
            "facility_sub_region_1" = 'California'
        GROUP BY
            "facility_sub_region_2_code", "facility_sub_region_2"
    ) v
JOIN
    (
        SELECT
            "geo_id" AS "county_fips",
            "total_pop"
        FROM
            "COVID19_USA"."CENSUS_BUREAU_ACS"."COUNTY_2018_5YR"
        WHERE
            "geo_id" LIKE '06%'
        ) p
    ON
        v."county_fips" = p."county_fips"
    ORDER BY
        "number_of_vaccine_sites_per_1000_people" DESC NULLS LAST;