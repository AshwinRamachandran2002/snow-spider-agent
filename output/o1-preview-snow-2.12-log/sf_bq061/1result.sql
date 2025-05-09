SELECT
    tract."geo_id",
    tract."tract_ce"
FROM
    CENSUS_BUREAU_ACS_1.GEO_CENSUS_TRACTS.CENSUS_TRACTS_CALIFORNIA AS tract
    JOIN CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.CENSUSTRACT_2015_5YR AS data2015
        ON tract."geo_id" = data2015."geo_id"
    JOIN CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.CENSUSTRACT_2018_5YR AS data2018
        ON tract."geo_id" = data2018."geo_id"
WHERE
    data2015."median_income" IS NOT NULL
    AND data2018."median_income" IS NOT NULL
ORDER BY
    (data2018."median_income" - data2015."median_income") DESC NULLS LAST
LIMIT 1;