SELECT 
  ((AVG(CASE WHEN TO_DATE("date", 'YYYY-MM-DD') BETWEEN '2020-01-01' AND '2020-12-31' THEN TRY_TO_DOUBLE("symptom_anosmia") END) -
    AVG(CASE WHEN TO_DATE("date", 'YYYY-MM-DD') BETWEEN '2019-01-01' AND '2019-12-31' THEN TRY_TO_DOUBLE("symptom_anosmia") END)) /
    AVG(CASE WHEN TO_DATE("date", 'YYYY-MM-DD') BETWEEN '2019-01-01' AND '2019-12-31' THEN TRY_TO_DOUBLE("symptom_anosmia") END)) * 100 AS "Percentage_change"
FROM "COVID19_SYMPTOM_SEARCH"."COVID19_SYMPTOM_SEARCH"."SYMPTOM_SEARCH_SUB_REGION_2_WEEKLY"
WHERE "sub_region_2" IN (
  'Bronx County', 'Queens County', 'Kings County', 'New York County', 'Richmond County'
);