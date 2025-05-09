WITH poverty_2015 AS (
    SELECT
        RIGHT(geo_id, 5) AS county_fips,
        SAFE_MULTIPLY(SAFE_DIVIDE(poverty, NULLIF(pop_determined_poverty_status, 0)), 100) AS poverty_rate
    FROM
        `bigquery-public-data.census_bureau_acs.county_2015_5yr`
    WHERE
        pop_determined_poverty_status > 0
),
births_2016 AS (
    SELECT
        County_of_Residence_FIPS AS county_fips,
        SUM(Births) AS total_births,
        SUM(CASE WHEN Maternal_Morbidity_YN = 0 THEN Births ELSE 0 END) AS births_no_morbidity
    FROM
        `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
    WHERE
        EXTRACT(YEAR FROM Year) = 2016
    GROUP BY
        county_fips
),
data_2016 AS (
    SELECT
        p.county_fips,
        p.poverty_rate,
        SAFE_MULTIPLY(SAFE_DIVIDE(b.births_no_morbidity, b.total_births), 100) AS percent_no_morbidity
    FROM
        poverty_2015 p
    JOIN
        births_2016 b
    ON
        p.county_fips = b.county_fips
    WHERE
        b.total_births > 0
),
poverty_2016 AS (
    SELECT
        RIGHT(geo_id, 5) AS county_fips,
        SAFE_MULTIPLY(SAFE_DIVIDE(poverty, NULLIF(pop_determined_poverty_status, 0)), 100) AS poverty_rate
    FROM
        `bigquery-public-data.census_bureau_acs.county_2016_5yr`
    WHERE
        pop_determined_poverty_status > 0
),
births_2017 AS (
    SELECT
        County_of_Residence_FIPS AS county_fips,
        SUM(Births) AS total_births,
        SUM(CASE WHEN Maternal_Morbidity_YN = 0 THEN Births ELSE 0 END) AS births_no_morbidity
    FROM
        `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
    WHERE
        EXTRACT(YEAR FROM Year) = 2017
    GROUP BY
        county_fips
),
data_2017 AS (
    SELECT
        p.county_fips,
        p.poverty_rate,
        SAFE_MULTIPLY(SAFE_DIVIDE(b.births_no_morbidity, b.total_births), 100) AS percent_no_morbidity
    FROM
        poverty_2016 p
    JOIN
        births_2017 b
    ON
        p.county_fips = b.county_fips
    WHERE
        b.total_births > 0
),
poverty_2017 AS (
    SELECT
        RIGHT(geo_id, 5) AS county_fips,
        SAFE_MULTIPLY(SAFE_DIVIDE(poverty, NULLIF(pop_determined_poverty_status, 0)), 100) AS poverty_rate
    FROM
        `bigquery-public-data.census_bureau_acs.county_2017_5yr`
    WHERE
        pop_determined_poverty_status > 0
),
births_2018 AS (
    SELECT
        County_of_Residence_FIPS AS county_fips,
        SUM(Births) AS total_births,
        SUM(CASE WHEN Maternal_Morbidity_YN = 0 THEN Births ELSE 0 END) AS births_no_morbidity
    FROM
        `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
    WHERE
        EXTRACT(YEAR FROM Year) = 2018
    GROUP BY
        county_fips
),
data_2018 AS (
    SELECT
        p.county_fips,
        p.poverty_rate,
        SAFE_MULTIPLY(SAFE_DIVIDE(b.births_no_morbidity, b.total_births), 100) AS percent_no_morbidity
    FROM
        poverty_2017 p
    JOIN
        births_2018 b
    ON
        p.county_fips = b.county_fips
    WHERE
        b.total_births > 0
)
SELECT
    2016 AS Year,
    ROUND(CORR(poverty_rate, percent_no_morbidity), 4) AS Pearson_Correlation_Coefficient
FROM
    data_2016

UNION ALL

SELECT
    2017 AS Year,
    ROUND(CORR(poverty_rate, percent_no_morbidity), 4) AS Pearson_Correlation_Coefficient
FROM
    data_2017

UNION ALL

SELECT
    2018 AS Year,
    ROUND(CORR(poverty_rate, percent_no_morbidity), 4) AS Pearson_Correlation_Coefficient
FROM
    data_2018

ORDER BY Year