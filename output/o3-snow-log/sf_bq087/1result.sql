WITH filtered AS (
    SELECT
        TO_DATE("date")                       AS week_start,
        "symptom_anosmia"::FLOAT              AS anosmia
    FROM   COVID19_SYMPTOM_SEARCH.COVID19_SYMPTOM_SEARCH.SYMPTOM_SEARCH_SUB_REGION_2_WEEKLY
    WHERE  "sub_region_2" IN ('Bronx County',
                              'Queens County',
                              'Kings County',
                              'New York County',
                              'Richmond County')
      AND  TO_DATE("date") BETWEEN '2019-01-01' AND '2020-12-31'
), yearly_avg AS (
    SELECT
        EXTRACT(YEAR FROM week_start) AS yr,
        AVG(anosmia)                  AS avg_weekly_anosmia
    FROM   filtered
    GROUP  BY yr
    HAVING yr IN (2019, 2020)
)
SELECT
    ROUND(
        (MAX(CASE WHEN yr = 2020 THEN avg_weekly_anosmia END) -
         MAX(CASE WHEN yr = 2019 THEN avg_weekly_anosmia END))
        / NULLIF(MAX(CASE WHEN yr = 2019 THEN avg_weekly_anosmia END), 0) * 100,
        4
    ) AS "percentage_change"
FROM yearly_avg;