WITH weekly_data AS (
    SELECT
        TO_DATE("date")                               AS week_date,
        CAST("symptom_anosmia" AS FLOAT)              AS anosmia_value
    FROM COVID19_SYMPTOM_SEARCH.COVID19_SYMPTOM_SEARCH.SYMPTOM_SEARCH_SUB_REGION_2_WEEKLY
    WHERE "sub_region_1" = 'New York'
      AND "sub_region_2" IN (
            'Bronx County',
            'Queens County',
            'Kings County',
            'New York County',
            'Richmond County'
          )
      AND "date" BETWEEN '2019-01-01' AND '2020-12-31'
      AND "symptom_anosmia" IS NOT NULL
),
yearly_average AS (
    SELECT
        EXTRACT(YEAR FROM week_date)  AS year,
        AVG(anosmia_value)            AS avg_weekly_anosmia
    FROM weekly_data
    GROUP BY year
)
SELECT
    ( (MAX(CASE WHEN year = 2020 THEN avg_weekly_anosmia END) -
        MAX(CASE WHEN year = 2019 THEN avg_weekly_anosmia END))
      / MAX(CASE WHEN year = 2019 THEN avg_weekly_anosmia END)
    ) * 100  AS percentage_change_2019_to_2020
FROM yearly_average;