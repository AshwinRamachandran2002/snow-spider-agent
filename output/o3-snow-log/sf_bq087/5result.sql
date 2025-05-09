WITH filtered AS (
    SELECT
        TO_DATE("date") AS dt,
        YEAR(TO_DATE("date"))  AS yr,
        TRY_TO_DOUBLE("symptom_anosmia") AS anosmia_val
    FROM COVID19_SYMPTOM_SEARCH.COVID19_SYMPTOM_SEARCH.SYMPTOM_SEARCH_SUB_REGION_2_WEEKLY
    WHERE "sub_region_1" = 'New York'
      AND "sub_region_2" IN (
            'Bronx County',
            'Queens County',
            'Kings County',
            'New York County',
            'Richmond County'
          )
      AND TO_DATE("date") BETWEEN '2019-01-01' AND '2020-12-31'
),
avg_by_year AS (
    SELECT
        yr,
        AVG(anosmia_val) AS avg_anosmia
    FROM filtered
    GROUP BY yr
    HAVING yr IN (2019, 2020)
),
pivot AS (
    SELECT
        MAX(CASE WHEN yr = 2019 THEN avg_anosmia END) AS avg_2019,
        MAX(CASE WHEN yr = 2020 THEN avg_anosmia END) AS avg_2020
    FROM avg_by_year
)
SELECT
    (avg_2020 - avg_2019) / avg_2019 * 100 AS percentage_change
FROM pivot;