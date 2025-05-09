WITH nyc_weekly AS (
  SELECT
    DATE(`date`)                                   AS week_start,
    CAST(`symptom_anosmia` AS FLOAT64)             AS anosmia
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_sub_region_2_weekly`
  WHERE `country_region_code` = 'US'
    AND `sub_region_1_code`   = 'US-NY'
    AND `sub_region_2` IN ('Bronx County',
                           'Queens County',
                           'Kings County',
                           'New York County',
                           'Richmond County')
)

SELECT
  AVG(CASE WHEN week_start BETWEEN '2019-01-01' AND '2019-12-31'
           THEN anosmia END)                                    AS avg_anosmia_2019,
  AVG(CASE WHEN week_start BETWEEN '2020-01-01' AND '2020-12-31'
           THEN anosmia END)                                    AS avg_anosmia_2020,
  SAFE_DIVIDE(
     AVG(CASE WHEN week_start BETWEEN '2020-01-01' AND '2020-12-31' THEN anosmia END) -
     AVG(CASE WHEN week_start BETWEEN '2019-01-01' AND '2019-12-31' THEN anosmia END),
     AVG(CASE WHEN week_start BETWEEN '2019-01-01' AND '2019-12-31' THEN anosmia END)
  ) * 100                                                      AS pct_change_2019_to_2020
FROM nyc_weekly;