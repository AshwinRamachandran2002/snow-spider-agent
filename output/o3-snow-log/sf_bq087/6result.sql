WITH nyc_data AS (
    SELECT
        YEAR("date")                                   AS yr,
        DATE_TRUNC('week', "date")                     AS week_start,
        "symptom_Anosmia"
    FROM COVID19_SYMPTOM_SEARCH.COVID19_SYMPTOM_SEARCH.SYMPTOM_SEARCH_SUB_REGION_2_DAILY
    WHERE "date" BETWEEN '2019-01-01' AND '2020-12-31'
      AND "sub_region_2" IN ('Bronx County',
                             'Queens County',
                             'Kings County',
                             'New York County',
                             'Richmond County')
),
weekly_avg AS (
    SELECT
        yr,
        week_start,
        AVG("symptom_Anosmia") AS weekly_avg
    FROM nyc_data
    GROUP BY yr, week_start
),
yearly_avg AS (
    SELECT
        yr,
        AVG(weekly_avg) AS avg_weekly
    FROM weekly_avg
    GROUP BY yr
)
SELECT
    ROUND(
        (MAX(CASE WHEN yr = 2020 THEN avg_weekly END) -
         MAX(CASE WHEN yr = 2019 THEN avg_weekly END))
        / NULLIF(MAX(CASE WHEN yr = 2019 THEN avg_weekly END), 0) * 100,
        4
    ) AS "pct_change_2019_to_2020"
FROM yearly_avg;