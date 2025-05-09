SELECT
  Year,
  ROUND(CORR(poverty_rate, percentage_without_morbidity), 4) AS Pearson_Correlation_Coefficient
FROM (
  SELECT
    n.Year,
    n.county_fips,
    n.percentage_without_morbidity,
    p.poverty_rate
  FROM (
    SELECT
      EXTRACT(YEAR FROM `Year`) AS Year,
      `County_of_Residence_FIPS` AS county_fips,
      (SUM(CASE WHEN `Maternal_Morbidity_YN` = 0 THEN `Births` ELSE 0 END) / SUM(`Births`)) * 100 AS percentage_without_morbidity
    FROM
      `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
    WHERE
      EXTRACT(YEAR FROM `Year`) BETWEEN 2016 AND 2018
    GROUP BY
      Year, county_fips
    HAVING SUM(`Births`) > 0
  ) n
  JOIN (
    SELECT
      2016 AS Year,
      RIGHT(geo_id, 5) AS county_fips,
      (poverty / pop_determined_poverty_status) * 100 AS poverty_rate
    FROM
      `bigquery-public-data.census_bureau_acs.county_2015_5yr`
    WHERE
      poverty IS NOT NULL AND pop_determined_poverty_status > 0
    UNION ALL
    SELECT
      2017 AS Year,
      RIGHT(geo_id, 5) AS county_fips,
      (poverty / pop_determined_poverty_status) * 100 AS poverty_rate
    FROM
      `bigquery-public-data.census_bureau_acs.county_2016_5yr`
    WHERE
      poverty IS NOT NULL AND pop_determined_poverty_status > 0
    UNION ALL
    SELECT
      2018 AS Year,
      RIGHT(geo_id, 5) AS county_fips,
      (poverty / pop_determined_poverty_status) * 100 AS poverty_rate
    FROM
      `bigquery-public-data.census_bureau_acs.county_2017_5yr`
    WHERE
      poverty IS NOT NULL AND pop_determined_poverty_status > 0
  ) p
  ON
    n.Year = p.Year AND n.county_fips = p.county_fips
)
GROUP BY
  Year
ORDER BY
  Year