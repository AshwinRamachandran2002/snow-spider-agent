WITH avg_2019 AS (
    SELECT AVG("symptom_Anosmia") AS avg_2019
    FROM COVID19_SYMPTOM_SEARCH.COVID19_SYMPTOM_SEARCH."SYMPTOM_SEARCH_SUB_REGION_2_DAILY"
    WHERE "sub_region_2" IN ('New York County', 'Kings County', 'Queens County', 'Bronx County', 'Richmond County')
      AND "date" >= '2019-01-01' AND "date" <= '2019-12-31'
),
avg_2020 AS (
    SELECT AVG("symptom_Anosmia") AS avg_2020
    FROM COVID19_SYMPTOM_SEARCH.COVID19_SYMPTOM_SEARCH."SYMPTOM_SEARCH_SUB_REGION_2_DAILY"
    WHERE "sub_region_2" IN ('New York County', 'Kings County', 'Queens County', 'Bronx County', 'Richmond County')
      AND "date" >= '2020-01-01' AND "date" <= '2020-12-31'
)
SELECT 
    ROUND(((avg_2020.avg_2020 - avg_2019.avg_2019) / avg_2019.avg_2019) * 100, 4) AS "Percentage_change_in_average_search_frequency"
FROM avg_2019, avg_2020;