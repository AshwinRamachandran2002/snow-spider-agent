WITH unemployment AS (
  -- Pull county–level unemployment rates for 2015 and 2018
  SELECT
    SUBSTR(geo_id, 10, 5)                                       AS county_fips,
    SAFE_DIVIDE(unemployed_pop, unemployed_pop + employed_pop)  AS unemp_rate,
    2015                                                        AS yr
  FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr`

  UNION ALL

  SELECT
    SUBSTR(geo_id, 10, 5)                                       AS county_fips,
    SAFE_DIVIDE(unemployed_pop, unemployed_pop + employed_pop)  AS unemp_rate,
    2018                                                        AS yr
  FROM `bigquery-public-data.census_bureau_acs.county_2018_5yr`
),
unemp_pivot AS (
  -- Place 2015 and 2018 unemployment rates onto the same row
  SELECT
    county_fips,
    MAX(CASE WHEN yr = 2015 THEN unemp_rate END) AS unemp_2015,
    MAX(CASE WHEN yr = 2018 THEN unemp_rate END) AS unemp_2018
  FROM unemployment
  GROUP BY county_fips
),
dual_enrollment AS (
  -- Pull dual-eligible enrollee counts for the two required dates
  SELECT
    FIPS                                                   AS county_fips,
    MAX(CASE WHEN Date = '2015-12-01' THEN Public_Total END) AS enroll_2015,
    MAX(CASE WHEN Date = '2018-12-01' THEN Public_Total END) AS enroll_2018
  FROM `bigquery-public-data.sdoh_cms_dual_eligible_enrollment.dual_eligible_enrollment_by_county_and_program`
  WHERE Date IN ('2015-12-01','2018-12-01')
  GROUP BY county_fips
),
qualifying_counties AS (
  -- Keep counties where unemployment ↑ and enrollment ↓
  SELECT
    u.county_fips
  FROM unemp_pivot        AS u
  JOIN dual_enrollment    AS d
  USING (county_fips)
  WHERE u.unemp_2018  > u.unemp_2015     -- unemployment increased
    AND d.enroll_2018 < d.enroll_2015    -- dual-eligible counts decreased
    AND u.unemp_2015  IS NOT NULL
    AND u.unemp_2018  IS NOT NULL
    AND d.enroll_2015 IS NOT NULL
    AND d.enroll_2018 IS NOT NULL
)

SELECT COUNT(*) AS county_count
FROM qualifying_counties;