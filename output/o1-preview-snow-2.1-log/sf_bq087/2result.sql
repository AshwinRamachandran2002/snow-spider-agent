SELECT
  ROUND(((avg_2020 - avg_2019) / avg_2019) * 100, 4) AS "Percentage_change_in_average_search_frequency"
FROM (
  SELECT 
    AVG(CASE WHEN DATE_PART('year', "date") = 2019 THEN "symptom_Anosmia" END) AS avg_2019,
    AVG(CASE WHEN DATE_PART('year', "date") = 2020 THEN "symptom_Anosmia" END) AS avg_2020
  FROM
    "COVID19_SYMPTOM_SEARCH"."COVID19_SYMPTOM_SEARCH"."SYMPTOM_SEARCH_SUB_REGION_2_DAILY"
  WHERE
    "sub_region_2" IN ('New York County', 'Kings County', 'Queens County', 'Bronx County', 'Richmond County')
    AND "symptom_Anosmia" IS NOT NULL
) AS averages;