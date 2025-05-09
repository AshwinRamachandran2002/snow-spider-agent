/*--------------------------------------------------------------------
  Count U.S. counties that meet BOTH of the following conditions:
    1.  Unemployed population increased from the 2015 ACS 5-year file
        to the 2018 ACS 5-year file.
    2.  Dual-eligible enrollee total fell between 1 Dec 2015 and
        1 Dec 2018.
--------------------------------------------------------------------*/
WITH acs AS (
  -- Pull unemployed-population counts for 2015 & 2018
  SELECT
    RIGHT(geo_id, 5)            AS fips,
    unemployed_pop              AS unemployed_cnt,
    2015                        AS yr
  FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr`

  UNION ALL

  SELECT
    RIGHT(geo_id, 5)            AS fips,
    unemployed_pop              AS unemployed_cnt,
    2018                        AS yr
  FROM `bigquery-public-data.census_bureau_acs.county_2018_5yr`
),
unemployment_increase AS (
  -- Keep counties whose unemployed-population count rose
  SELECT
    fips,
    MAX(CASE WHEN yr = 2015 THEN unemployed_cnt END) AS unemployed_2015,
    MAX(CASE WHEN yr = 2018 THEN unemployed_cnt END) AS unemployed_2018
  FROM acs
  GROUP BY fips
  HAVING unemployed_2018 > unemployed_2015
),
dual AS (
  -- Dual-eligible totals for the two snapshots
  SELECT
    LPAD(CAST(FIPS AS STRING), 5, '0') AS fips,
    Public_Total,
    Date
  FROM `bigquery-public-data.sdoh_cms_dual_eligible_enrollment.dual_eligible_enrollment_by_county_and_program`
  WHERE Date IN ('2015-12-01', '2018-12-01')
),
dual_decrease AS (
  -- Keep counties whose dual-eligible total fell
  SELECT
    fips,
    MAX(CASE WHEN Date = '2015-12-01' THEN Public_Total END) AS dual_2015,
    MAX(CASE WHEN Date = '2018-12-01' THEN Public_Total END) AS dual_2018
  FROM dual
  GROUP BY fips
  HAVING dual_2018 < dual_2015
)

-- Final answer: number of counties satisfying both criteria
SELECT COUNT(*) AS county_count
FROM unemployment_increase
JOIN dual_decrease USING (fips);