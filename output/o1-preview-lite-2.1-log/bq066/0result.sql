SELECT
    natality_data.Year,
    ROUND(CORR(poverty_data.poverty_rate, natality_data.percentage_without_morbidity), 4) AS Pearson_Correlation_Coefficient
FROM
    (
        SELECT
            total_births.Year,
            total_births.county_fips,
            (COALESCE(no_morbidity.births_without_morbidity, 0) / total_births.total_births) * 100 AS percentage_without_morbidity
        FROM
            (
                SELECT
                    EXTRACT(YEAR FROM Year) AS Year,
                    County_of_Residence_FIPS AS county_fips,
                    SUM(Births) AS total_births
                FROM
                    `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality`
                WHERE
                    EXTRACT(YEAR FROM Year) BETWEEN 2016 AND 2018
                GROUP BY
                    Year,
                    county_fips
            ) AS total_births
        LEFT JOIN
            (
                SELECT
                    EXTRACT(YEAR FROM Year) AS Year,
                    County_of_Residence_FIPS AS county_fips,
                    SUM(Births) AS births_without_morbidity
                FROM
                    `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
                WHERE
                    EXTRACT(YEAR FROM Year) BETWEEN 2016 AND 2018
                    AND Maternal_Morbidity_YN = 0
                GROUP BY
                    Year,
                    county_fips
            ) AS no_morbidity
        ON
            total_births.Year = no_morbidity.Year
            AND total_births.county_fips = no_morbidity.county_fips
        WHERE total_births.total_births > 0
    ) AS natality_data
JOIN
    (
        SELECT
            CAST(geo_id AS STRING) AS county_fips,
            (poverty / total_pop) * 100 AS poverty_rate,
            2015 AS census_year
        FROM
            `bigquery-public-data.census_bureau_acs.county_2015_5yr`
        WHERE
            total_pop > 0

        UNION ALL

        SELECT
            CAST(geo_id AS STRING) AS county_fips,
            (poverty / total_pop) * 100 AS poverty_rate,
            2016 AS census_year
        FROM
            `bigquery-public-data.census_bureau_acs.county_2016_5yr`
        WHERE
            total_pop > 0

        UNION ALL

        SELECT
            CAST(geo_id AS STRING) AS county_fips,
            (poverty / total_pop) * 100 AS poverty_rate,
            2017 AS census_year
        FROM
            `bigquery-public-data.census_bureau_acs.county_2017_5yr`
        WHERE
            total_pop > 0
    ) AS poverty_data
ON
    natality_data.county_fips = poverty_data.county_fips
    AND natality_data.Year - 1 = poverty_data.census_year
GROUP BY
    natality_data.Year
ORDER BY
    natality_data.Year;