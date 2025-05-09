/*--------------------------------------------------------------------
Did average annual wages (all industries) in Allegheny County, PA
(FIPS 42003) keep pace with nationwide CPI-U inflation between 1998
and 2017?  Return the two growth rates and a conclusion.
--------------------------------------------------------------------*/
WITH wage_raw AS (   -- grab the four quarters for each target year
  SELECT
    CAST(REGEXP_EXTRACT(_TABLE_SUFFIX, r'^(\d{4})') AS INT64) AS year,
    avg_wkly_wage_10_total_all_industries               AS wage,
    area_fips
  FROM `bigquery-public-data.bls_qcew.*`
  WHERE _TABLE_SUFFIX IN ('1998_q1','1998_q2','1998_q3','1998_q4',
                          '2017_q1','2017_q2','2017_q3','2017_q4')
),
county_wages AS (    -- average the four quarters to one value per year
  SELECT
    year,
    AVG(wage) AS avg_weekly_wage
  FROM wage_raw
  WHERE area_fips = '42003'             -- Allegheny County
  GROUP BY year
),
cpi AS (            -- average the 12 monthly CPI-U “All items” values
  SELECT
    year,
    AVG(value) AS avg_cpi
  FROM `bigquery-public-data.bls.cpi_u`
  WHERE series_id = 'CUSR0000SA0'       -- CPI-U, all items, SA
    AND year IN (1998, 2017)
  GROUP BY year
)
SELECT
  ROUND( (w17.avg_weekly_wage / w98.avg_weekly_wage - 1) * 100, 2) AS wage_growth_pct,
  ROUND( (c17.avg_cpi         / c98.avg_cpi         - 1) * 100, 2) AS cpi_growth_pct,
  CASE
    WHEN (w17.avg_weekly_wage / w98.avg_weekly_wage) >=
         (c17.avg_cpi         / c98.avg_cpi)
    THEN 'Wages kept pace with or exceeded inflation.'
    ELSE 'Wages did NOT keep pace with inflation.'
  END AS conclusion
FROM county_wages w98
JOIN county_wages w17 ON w98.year = 1998 AND w17.year = 2017
JOIN cpi          c98 ON c98.year = 1998
JOIN cpi          c17 ON c17.year = 2017;