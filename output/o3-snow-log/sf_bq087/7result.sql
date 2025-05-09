WITH county_weeks AS (
    SELECT
        "date",
        TRY_TO_DOUBLE("symptom_anosmia") AS anosmia_val,
        CASE 
            WHEN "date" BETWEEN '2019-01-01' AND '2019-12-31' THEN '2019'
            WHEN "date" BETWEEN '2020-01-01' AND '2020-12-31' THEN '2020'
        END AS yr
    FROM COVID19_SYMPTOM_SEARCH.COVID19_SYMPTOM_SEARCH.SYMPTOM_SEARCH_SUB_REGION_2_WEEKLY
    WHERE "sub_region_2" IN ('Bronx County','Queens County','Kings County','New York County','Richmond County')
          AND "date" BETWEEN '2019-01-01' AND '2020-12-31'
),
yearly_avg AS (
    SELECT
        yr,
        AVG(anosmia_val) AS avg_weekly_freq
    FROM county_weeks
    GROUP BY yr
)
SELECT
    ROUND(
        (
            (MAX(CASE WHEN yr = '2020' THEN avg_weekly_freq END)
             -
             MAX(CASE WHEN yr = '2019' THEN avg_weekly_freq END))
            /
            NULLIF(MAX(CASE WHEN yr = '2019' THEN avg_weekly_freq END), 0)
        ) * 100
    , 4) AS "PERCENT_CHANGE"
FROM yearly_avg;