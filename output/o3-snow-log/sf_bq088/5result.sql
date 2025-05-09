WITH base AS (
    SELECT
        TO_DATE("date")                            AS dt,
        CAST("symptom_anxiety"   AS FLOAT)         AS anxiety,
        CAST("symptom_depression" AS FLOAT)        AS depression
    FROM COVID19_SYMPTOM_SEARCH.COVID19_SYMPTOM_SEARCH.SYMPTOM_SEARCH_COUNTRY_WEEKLY
    WHERE "country_region" = 'United States'
          AND TO_DATE("date") >= '2019-01-01'
          AND TO_DATE("date") <  '2021-01-01'
),
period_avgs AS (
    SELECT
        CASE 
            WHEN dt >= '2019-01-01' AND dt < '2020-01-01' THEN '2019'
            WHEN dt >= '2020-01-01' AND dt < '2021-01-01' THEN '2020'
        END                                              AS period,
        AVG(anxiety)    AS avg_anxiety,
        AVG(depression) AS avg_depression
    FROM base
    GROUP BY period
),
pivot AS (
    SELECT
        MAX(CASE WHEN period = '2019' THEN avg_anxiety    END) AS avg_anxiety_2019,
        MAX(CASE WHEN period = '2020' THEN avg_anxiety    END) AS avg_anxiety_2020,
        MAX(CASE WHEN period = '2019' THEN avg_depression END) AS avg_depression_2019,
        MAX(CASE WHEN period = '2020' THEN avg_depression END) AS avg_depression_2020
    FROM period_avgs
)
SELECT
    avg_anxiety_2019,
    avg_anxiety_2020,
    (avg_anxiety_2020 - avg_anxiety_2019) / avg_anxiety_2019 * 100 AS anxiety_pct_increase,
    avg_depression_2019,
    avg_depression_2020,
    (avg_depression_2020 - avg_depression_2019) / avg_depression_2019 * 100 AS depression_pct_increase
FROM pivot;