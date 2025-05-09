SELECT 'Anxiety' AS "Symptom",
    ROUND(AVG(CASE WHEN EXTRACT(year FROM TO_DATE("date", 'YYYY-MM-DD')) = 2019 THEN CAST("symptom_anxiety" AS FLOAT) END), 4) AS "Average_2019",
    ROUND(AVG(CASE WHEN EXTRACT(year FROM TO_DATE("date", 'YYYY-MM-DD')) = 2020 THEN CAST("symptom_anxiety" AS FLOAT) END), 4) AS "Average_2020",
    ROUND(((AVG(CASE WHEN EXTRACT(year FROM TO_DATE("date", 'YYYY-MM-DD')) = 2020 THEN CAST("symptom_anxiety" AS FLOAT) END) - AVG(CASE WHEN EXTRACT(year FROM TO_DATE("date", 'YYYY-MM-DD')) = 2019 THEN CAST("symptom_anxiety" AS FLOAT) END)) / AVG(CASE WHEN EXTRACT(year FROM TO_DATE("date", 'YYYY-MM-DD')) = 2019 THEN CAST("symptom_anxiety" AS FLOAT) END) * 100), 4) AS "Percentage_Increase"
FROM "COVID19_SYMPTOM_SEARCH"."COVID19_SYMPTOM_SEARCH"."SYMPTOM_SEARCH_COUNTRY_WEEKLY"
WHERE "country_region" = 'United States' AND EXTRACT(year FROM TO_DATE("date", 'YYYY-MM-DD')) IN (2019, 2020)

UNION ALL

SELECT 'Depression' AS "Symptom",
    ROUND(AVG(CASE WHEN EXTRACT(year FROM TO_DATE("date", 'YYYY-MM-DD')) = 2019 THEN CAST("symptom_depression" AS FLOAT) END), 4) AS "Average_2019",
    ROUND(AVG(CASE WHEN EXTRACT(year FROM TO_DATE("date", 'YYYY-MM-DD')) = 2020 THEN CAST("symptom_depression" AS FLOAT) END), 4) AS "Average_2020",
    ROUND(((AVG(CASE WHEN EXTRACT(year FROM TO_DATE("date", 'YYYY-MM-DD')) = 2020 THEN CAST("symptom_depression" AS FLOAT) END) - AVG(CASE WHEN EXTRACT(year FROM TO_DATE("date", 'YYYY-MM-DD')) = 2019 THEN CAST("symptom_depression" AS FLOAT) END)) / AVG(CASE WHEN EXTRACT(year FROM TO_DATE("date", 'YYYY-MM-DD')) = 2019 THEN CAST("symptom_depression" AS FLOAT) END) * 100), 4) AS "Percentage_Increase"
FROM "COVID19_SYMPTOM_SEARCH"."COVID19_SYMPTOM_SEARCH"."SYMPTOM_SEARCH_COUNTRY_WEEKLY"
WHERE "country_region" = 'United States' AND EXTRACT(year FROM TO_DATE("date", 'YYYY-MM-DD')) IN (2019, 2020);