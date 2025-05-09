-- Overall % change in average weekly 'Anosmia' searches (NYC counties, 2019 → 2020)
WITH nyc_weekly AS (
  SELECT
    EXTRACT(YEAR FROM DATE(`date`)) AS yr,
    SAFE_CAST(`symptom_anosmia` AS FLOAT64)          AS anosmia_score
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_sub_region_2_weekly`
  WHERE `sub_region_1` = 'New York'
    AND `sub_region_2` IN ('Bronx County','Queens County','Kings County',
                           'New York County','Richmond County')
    AND `date` BETWEEN '2019-01-01' AND '2020-12-31'
),
yearly_avg AS (
  SELECT
    AVG(CASE WHEN yr = 2019 THEN anosmia_score END) AS avg_2019,
    AVG(CASE WHEN yr = 2020 THEN anosmia_score END) AS avg_2020
  FROM nyc_weekly
)
SELECT
  avg_2019,
  avg_2020,
  ROUND( (avg_2020 - avg_2019) / avg_2019 * 100, 2 ) AS pct_change
FROM yearly_avg;