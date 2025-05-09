WITH county_weeks AS (
  SELECT
    PARSE_DATE('%Y-%m-%d', `date`)            AS week_start_date,
    CAST(symptom_anosmia AS FLOAT64)          AS anosmia_value
  FROM
    `bigquery-public-data.covid19_symptom_search.symptom_search_sub_region_2_weekly`
  WHERE
        country_region          = 'United States'
    AND sub_region_1            = 'New York'
    AND sub_region_2 IN ('Bronx County',
                         'Queens County',
                         'Kings County',
                         'New York County',
                         'Richmond County')
    AND `date` BETWEEN '2019-01-01' AND '2020-12-31'
),

/* average the five counties for each epidemiological week */
week_avg AS (
  SELECT
    week_start_date,
    AVG(anosmia_value) AS avg_across_counties
  FROM county_weeks
  GROUP BY week_start_date
),

/* get the average weekly value for each calendar year */
year_avg AS (
  SELECT
    EXTRACT(YEAR FROM week_start_date) AS yr,
    AVG(avg_across_counties)          AS avg_weekly_anosmia
  FROM week_avg
  GROUP BY yr
)

/* calculate overall % change from 2019 to 2020 */
SELECT
  (MAX(CASE WHEN yr = 2020 THEN avg_weekly_anosmia END) -
   MAX(CASE WHEN yr = 2019 THEN avg_weekly_anosmia END))
  / MAX(CASE WHEN yr = 2019 THEN avg_weekly_anosmia END) * 100
    AS percentage_change_in_avg_weekly_search_frequency
FROM year_avg;