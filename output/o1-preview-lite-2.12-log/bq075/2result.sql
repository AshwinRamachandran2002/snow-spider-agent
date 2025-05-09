WITH hiring AS (
  SELECT 'Asian' AS `Group`, race_asian AS value FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE report_year = 2021 AND workforce = 'overall'
  UNION ALL
  SELECT 'Black', race_black FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE report_year = 2021 AND workforce = 'overall'
  UNION ALL
  SELECT 'Hispanic/Latinx', race_hispanic_latinx FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE report_year = 2021 AND workforce = 'overall'
  UNION ALL
  SELECT 'White', race_white FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE report_year = 2021 AND workforce = 'overall'
  UNION ALL
  SELECT 'U.S. Women', gender_us_women FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE report_year = 2021 AND workforce = 'overall'
  UNION ALL
  SELECT 'U.S. Men', gender_us_men FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE report_year = 2021 AND workforce = 'overall'
),
representation AS (
  SELECT 'Asian' AS `Group`, race_asian AS value FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE report_year = 2021 AND workforce = 'overall'
  UNION ALL
  SELECT 'Black', race_black FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE report_year = 2021 AND workforce = 'overall'
  UNION ALL
  SELECT 'Hispanic/Latinx', race_hispanic_latinx FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE report_year = 2021 AND workforce = 'overall'
  UNION ALL
  SELECT 'White', race_white FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE report_year = 2021 AND workforce = 'overall'
  UNION ALL
  SELECT 'U.S. Women', gender_us_women FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE report_year = 2021 AND workforce = 'overall'
  UNION ALL
  SELECT 'U.S. Men', gender_us_men FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE report_year = 2021 AND workforce = 'overall'
),
bls AS (
  SELECT 'Asian' AS `Group`, AVG(percent_asian) AS value FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021 AND industry_group IN ('Internet publishing and broadcasting and web search portals', 'Computer systems design and related services')
  UNION ALL
  SELECT 'Black', AVG(percent_black_or_african_american) FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021 AND industry_group IN ('Internet publishing and broadcasting and web search portals', 'Computer systems design and related services')
  UNION ALL
  SELECT 'Hispanic/Latinx', AVG(percent_hispanic_or_latino) FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021 AND industry_group IN ('Internet publishing and broadcasting and web search portals', 'Computer systems design and related services')
  UNION ALL
  SELECT 'White', AVG(percent_white) FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021 AND industry_group IN ('Internet publishing and broadcasting and web search portals', 'Computer systems design and related services')
  UNION ALL
  SELECT 'U.S. Women', AVG(percent_women) FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021 AND industry_group IN ('Internet publishing and broadcasting and web search portals', 'Computer systems design and related services')
  UNION ALL
  SELECT 'U.S. Men', AVG(1 - percent_women) FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021 AND industry_group IN ('Internet publishing and broadcasting and web search portals', 'Computer systems design and related services')
)
SELECT hiring.`Group`,
  ROUND(hiring.value * 100, 4) AS Workforce_Hiring_Percentage,
  ROUND(representation.value * 100, 4) AS Workforce_Representation_Percentage,
  ROUND(bls.value * 100, 4) AS BLS_Percentage
FROM hiring
JOIN representation USING (`Group`)
JOIN bls USING (`Group`)
ORDER BY CASE hiring.`Group`
    WHEN 'Asian' THEN 1
    WHEN 'Black' THEN 2
    WHEN 'Hispanic/Latinx' THEN 3
    WHEN 'White' THEN 4
    WHEN 'U.S. Women' THEN 5
    WHEN 'U.S. Men' THEN 6
    ELSE 7
  END;