-- Task: Please calculate the average levels of anxiety symptoms from the weekly country data for the United States during the periods from January 1, 2019, to January 1, 2020, and from January 1, 2020, to January 1, 2021.

SELECT
  'Anxiety' AS "Symptom",
  ROUND(AVG(CASE WHEN YEAR(TO_DATE("date", 'YYYY-MM-DD')) = 2019 THEN TRY_CAST("symptom_anxiety" AS FLOAT) END), 4) AS "Average_2019",
  ROUND(AVG(CASE WHEN YEAR(TO_DATE("date", 'YYYY-MM-DD')) = 2020 THEN TRY_CAST("symptom_anxiety" AS FLOAT) END), 4) AS "Average_2020"
FROM
  "COVID19_SYMPTOM_SEARCH"."COVID19_SYMPTOM_SEARCH"."SYMPTOM_SEARCH_COUNTRY_WEEKLY"
WHERE
  "country_region" = 'United States' AND
  YEAR(TO_DATE("date", 'YYYY-MM-DD')) IN (2019, 2020);