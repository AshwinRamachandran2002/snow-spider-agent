WITH natality AS (
    SELECT
        EXTRACT(YEAR FROM "Year") AS "Year",
        LPAD(CAST("County_of_Residence_FIPS" AS VARCHAR), 5, '0') AS county_fips,
        SUM("Births") AS total_births,
        SUM(CASE WHEN "Maternal_Morbidity_YN" = 0 THEN "Births" ELSE 0 END) AS births_no_morbidity
    FROM "SDOH"."SDOH_CDC_WONDER_NATALITY"."COUNTY_NATALITY_BY_MATERNAL_MORBIDITY"
    WHERE EXTRACT(YEAR FROM "Year") IN (2016, 2017, 2018)
    GROUP BY EXTRACT(YEAR FROM "Year"), LPAD(CAST("County_of_Residence_FIPS" AS VARCHAR), 5, '0')
),
poverty AS (
    SELECT
        2016 AS "Year",
        RIGHT("geo_id", 5) AS county_fips,
        ("poverty" / NULLIF("pop_determined_poverty_status", 0)) * 100 AS poverty_rate
    FROM "SDOH"."CENSUS_BUREAU_ACS"."COUNTY_2015_5YR"
    WHERE "pop_determined_poverty_status" > 0
    UNION ALL
    SELECT
        2017 AS "Year",
        RIGHT("geo_id", 5) AS county_fips,
        ("poverty" / NULLIF("pop_determined_poverty_status", 0)) * 100 AS poverty_rate
    FROM "SDOH"."CENSUS_BUREAU_ACS"."COUNTY_2016_5YR"
    WHERE "pop_determined_poverty_status" > 0
    UNION ALL
    SELECT
        2018 AS "Year",
        RIGHT("geo_id", 5) AS county_fips,
        ("poverty" / NULLIF("pop_determined_poverty_status", 0)) * 100 AS poverty_rate
    FROM "SDOH"."CENSUS_BUREAU_ACS"."COUNTY_2017_5YR"
    WHERE "pop_determined_poverty_status" > 0
),
combined AS (
    SELECT
        n."Year",
        n.county_fips,
        n.total_births,
        n.births_no_morbidity,
        (n.births_no_morbidity / NULLIF(n.total_births, 0)) * 100 AS percent_no_morbidity,
        p.poverty_rate
    FROM natality n
    JOIN poverty p ON n."Year" = p."Year" AND n.county_fips = p.county_fips
    WHERE n.total_births > 0 AND p.poverty_rate IS NOT NULL
)
SELECT
    "Year",
    ROUND(CORR(poverty_rate, percent_no_morbidity), 4) AS "Pearson_correlation_coefficient"
FROM combined
GROUP BY "Year"
ORDER BY "Year";