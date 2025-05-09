WITH data AS (
    SELECT
        "Year",
        "poverty_rate",
        "pct_births_without_morbidity"
    FROM
    (
        SELECT
            '2016' AS "Year",
            CAST(census2015."geo_id" AS INT) AS "FIPS",
            census2015."poverty" AS "poverty_rate",
            (COALESCE(births_without_morbidity_2016."births_without_morbidity", 0) / total_births_2016."total_births") * 100 AS "pct_births_without_morbidity"
        FROM "SDOH"."CENSUS_BUREAU_ACS"."COUNTY_2015_5YR" census2015
        INNER JOIN (
            SELECT
                CAST("County_of_Residence_FIPS" AS INT) AS "FIPS",
                SUM("Births") AS "total_births"
            FROM "SDOH"."SDOH_CDC_WONDER_NATALITY"."COUNTY_NATALITY"
            WHERE "Year" = '2016-01-01'
            GROUP BY "County_of_Residence_FIPS"
        ) total_births_2016
        ON total_births_2016."FIPS" = CAST(census2015."geo_id" AS INT)
        LEFT JOIN (
            SELECT
                CAST("County_of_Residence_FIPS" AS INT) AS "FIPS",
                SUM("Births") AS "births_without_morbidity"
            FROM "SDOH"."SDOH_CDC_WONDER_NATALITY"."COUNTY_NATALITY_BY_MATERNAL_MORBIDITY"
            WHERE "Year" = '2016-01-01' AND "Maternal_Morbidity_YN" = 0
            GROUP BY "County_of_Residence_FIPS"
        ) births_without_morbidity_2016
        ON births_without_morbidity_2016."FIPS" = total_births_2016."FIPS"
        WHERE total_births_2016."total_births" > 0

        UNION ALL

        SELECT
            '2017' AS "Year",
            CAST(census2016."geo_id" AS INT) AS "FIPS",
            census2016."poverty" AS "poverty_rate",
            (COALESCE(births_without_morbidity_2017."births_without_morbidity", 0) / total_births_2017."total_births") * 100 AS "pct_births_without_morbidity"
        FROM "SDOH"."CENSUS_BUREAU_ACS"."COUNTY_2016_5YR" census2016
        INNER JOIN (
            SELECT
                CAST("County_of_Residence_FIPS" AS INT) AS "FIPS",
                SUM("Births") AS "total_births"
            FROM "SDOH"."SDOH_CDC_WONDER_NATALITY"."COUNTY_NATALITY"
            WHERE "Year" = '2017-01-01'
            GROUP BY "County_of_Residence_FIPS"
        ) total_births_2017
        ON total_births_2017."FIPS" = CAST(census2016."geo_id" AS INT)
        LEFT JOIN (
            SELECT
                CAST("County_of_Residence_FIPS" AS INT) AS "FIPS",
                SUM("Births") AS "births_without_morbidity"
            FROM "SDOH"."SDOH_CDC_WONDER_NATALITY"."COUNTY_NATALITY_BY_MATERNAL_MORBIDITY"
            WHERE "Year" = '2017-01-01' AND "Maternal_Morbidity_YN" = 0
            GROUP BY "County_of_Residence_FIPS"
        ) births_without_morbidity_2017
        ON births_without_morbidity_2017."FIPS" = total_births_2017."FIPS"
        WHERE total_births_2017."total_births" > 0

        UNION ALL

        SELECT
            '2018' AS "Year",
            CAST(census2017."geo_id" AS INT) AS "FIPS",
            census2017."poverty" AS "poverty_rate",
            (COALESCE(births_without_morbidity_2018."births_without_morbidity", 0) / total_births_2018."total_births") * 100 AS "pct_births_without_morbidity"
        FROM "SDOH"."CENSUS_BUREAU_ACS"."COUNTY_2017_5YR" census2017
        INNER JOIN (
            SELECT
                CAST("County_of_Residence_FIPS" AS INT) AS "FIPS",
                SUM("Births") AS "total_births"
            FROM "SDOH"."SDOH_CDC_WONDER_NATALITY"."COUNTY_NATALITY"
            WHERE "Year" = '2018-01-01'
            GROUP BY "County_of_Residence_FIPS"
        ) total_births_2018
        ON total_births_2018."FIPS" = CAST(census2017."geo_id" AS INT)
        LEFT JOIN (
            SELECT
                CAST("County_of_Residence_FIPS" AS INT) AS "FIPS",
                SUM("Births") AS "births_without_morbidity"
            FROM "SDOH"."SDOH_CDC_WONDER_NATALITY"."COUNTY_NATALITY_BY_MATERNAL_MORBIDITY"
            WHERE "Year" = '2018-01-01' AND "Maternal_Morbidity_YN" = 0
            GROUP BY "County_of_Residence_FIPS"
        ) births_without_morbidity_2018
        ON births_without_morbidity_2018."FIPS" = total_births_2018."FIPS"
        WHERE total_births_2018."total_births" > 0
    )
),
correlations AS (
    SELECT
        "Year",
        CORR("poverty_rate", "pct_births_without_morbidity") AS "Pearson_correlation_coefficient"
    FROM data
    GROUP BY "Year"
)
SELECT
    "Year",
    ROUND("Pearson_correlation_coefficient", 4) AS "Pearson_correlation_coefficient"
FROM correlations
ORDER BY "Year";