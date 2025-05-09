WITH filtered AS (
    SELECT
        "date",
        "symptom_Anosmia"
    FROM
        "COVID19_SYMPTOM_SEARCH"."COVID19_SYMPTOM_SEARCH"."SYMPTOM_SEARCH_SUB_REGION_2_DAILY"
    WHERE
        "sub_region_1" = 'New York'
        AND "sub_region_2" IN ('Bronx County','Queens County','Kings County','New York County','Richmond County')
        AND "date" BETWEEN '2019-01-01' AND '2020-12-31'
        AND "symptom_Anosmia" IS NOT NULL
),
weekly AS (
    SELECT
        DATE_TRUNC('week', "date") AS week_start,
        AVG("symptom_Anosmia")       AS weekly_avg
    FROM filtered
    GROUP BY week_start
),
avg_year AS (
    SELECT
        YEAR(week_start)            AS yr,
        AVG(weekly_avg)             AS avg_weekly
    FROM weekly
    GROUP BY yr
),
pivot AS (
    SELECT
        MAX(CASE WHEN yr = 2019 THEN avg_weekly END) AS avg_2019,
        MAX(CASE WHEN yr = 2020 THEN avg_weekly END) AS avg_2020
    FROM avg_year
)
SELECT
    ROUND(((avg_2020 - avg_2019) / avg_2019) * 100, 4) AS percentage_change
FROM pivot;