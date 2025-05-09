WITH weekly_data AS (
    SELECT
        DATE_TRUNC('week', "date") AS "week_start",
        EXTRACT(YEAR FROM "date") AS "year",
        AVG("symptom_Anosmia") AS weekly_avg
    FROM "COVID19_SYMPTOM_SEARCH"."COVID19_SYMPTOM_SEARCH"."SYMPTOM_SEARCH_SUB_REGION_2_DAILY"
    WHERE "date" BETWEEN '2019-01-01' AND '2020-12-31'
      AND "sub_region_2" IN ('Bronx County', 'Queens County', 'Kings County', 'New York County', 'Richmond County')
      AND "symptom_Anosmia" IS NOT NULL
    GROUP BY "week_start", "year"
)
SELECT
    ROUND(((avg_weekly_avg_2020 - avg_weekly_avg_2019) / avg_weekly_avg_2019) * 100, 4) AS "percentage_change:float"
FROM (
    SELECT
        AVG(CASE WHEN "year" = 2019 THEN weekly_avg END) AS avg_weekly_avg_2019,
        AVG(CASE WHEN "year" = 2020 THEN weekly_avg END) AS avg_weekly_avg_2020
    FROM weekly_data
) t;