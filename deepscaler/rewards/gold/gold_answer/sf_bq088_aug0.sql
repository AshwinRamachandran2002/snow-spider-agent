-- Task: Calculate the average levels of anxiety and depression symptoms from the weekly country data for the United States during 2019 and 2020. Then, compute the percentage increase in these average symptom levels from 2019 to 2020.

SELECT
  'Anxiety' AS "Symptom",
  ROUND(AVG(CASE WHEN YEAR(TO_DATE("date", 'YYYY-MM-DD')) = 2019 THEN TRY_CAST("symptom_anxiety" AS FLOAT) END), 4) AS "Average_2019",
  ROUND(AVG(CASE WHEN YEAR(TO_DATE("date", 'YYYY-MM-DD')) = 2020 THEN TRY_CAST("symptom_anxiety" AS FLOAT) END), 4) AS "Average_2020",
  ROUND(
    (
      AVG(CASE WHEN YEAR(TO_DATE("date", 'YYYY-MM-DD')) = 2020 THEN TRY_CAST("symptom_anxiety" AS FLOAT) END) -
      AVG(CASE WHEN YEAR(TO_DATE("date", 'YYYY-MM-DD')) = 2019 THEN TRY_CAST("symptom_anxiety" AS FLOAT) END)
    ) /
    AVG(CASE WHEN YEAR(TO_DATE("date", 'YYYY-MM-DD')) = 2019 THEN TRY_CAST("symptom_anxiety" AS FLOAT) END) * 100, 4
  ) AS "Percentage_Increase"
FROM
  "COVID19_SYMPTOM_SEARCH"."COVID19_SYMPTOM_SEARCH"."SYMPTOM_SEARCH_COUNTRY_WEEKLY"
WHERE
  "country_region" = 'United States' AND
  YEAR(TO_DATE("date", 'YYYY-MM-DD')) IN (2019, 2020)

UNION ALL

SELECT
  'Depression' AS "Symptom",
  ROUND(AVG(CASE WHEN YEAR(TO_DATE("date", 'YYYY-MM-DD')) = 2019 THEN TRY_CAST("symptom_depression" AS FLOAT) END), 4) AS "Average_2019",
  ROUND(AVG(CASE WHEN YEAR(TO_DATE("date", 'YYYY-MM-DD')) = 2020 THEN TRY_CAST("symptom_depression" AS FLOAT) END), 4) AS "Average_2020",
  ROUND(
    (
      AVG(CASE WHEN YEAR(TO_DATE("date", 'YYYY-MM-DD')) = 2020 THEN TRY_CAST("symptom_depression" AS FLOAT) END) -
      AVG(CASE WHEN YEAR(TO_DATE("date", 'YYYY-MM-DD')) = 2019 THEN TRY_CAST("symptom_depression" AS FLOAT) END)
    ) /
    AVG(CASE WHEN YEAR(TO_DATE("date", 'YYYY-MM-DD')) = 2019 THEN TRY_CAST("symptom_depression" AS FLOAT) END) * 100, 4
  ) AS "Percentage_Increase"
FROM
  "COVID19_SYMPTOM_SEARCH"."COVID19_SYMPTOM_SEARCH"."SYMPTOM_SEARCH_COUNTRY_WEEKLY"
WHERE
  "country_region" = 'United States' AND
  YEAR(TO_DATE("date", 'YYYY-MM-DD')) IN (2019, 2020);