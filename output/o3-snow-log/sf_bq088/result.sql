WITH filtered AS (
    SELECT
        TO_DATE("date")                                   AS dt,
        TRY_TO_DOUBLE("symptom_anxiety")                  AS anxiety,
        TRY_TO_DOUBLE("symptom_depression")               AS depression
    FROM COVID19_SYMPTOM_SEARCH.COVID19_SYMPTOM_SEARCH.SYMPTOM_SEARCH_COUNTRY_WEEKLY
    WHERE "country_region" = 'United States'
),
period_avgs AS (
    SELECT
        '2019'                                            AS period,
        AVG(anxiety)                                      AS avg_anxiety,
        AVG(depression)                                   AS avg_depression
    FROM filtered
    WHERE dt >= '2019-01-01' AND dt < '2020-01-01'
    
    UNION ALL
    
    SELECT
        '2020'                                            AS period,
        AVG(anxiety)                                      AS avg_anxiety,
        AVG(depression)                                   AS avg_depression
    FROM filtered
    WHERE dt >= '2020-01-01' AND dt < '2021-01-01'
),
pivoted AS (
    SELECT
        MAX(CASE WHEN period = '2019' THEN avg_anxiety END)    AS avg_anxiety_2019,
        MAX(CASE WHEN period = '2019' THEN avg_depression END) AS avg_depression_2019,
        MAX(CASE WHEN period = '2020' THEN avg_anxiety END)    AS avg_anxiety_2020,
        MAX(CASE WHEN period = '2020' THEN avg_depression END) AS avg_depression_2020
    FROM period_avgs
)
SELECT
    avg_anxiety_2019,
    avg_anxiety_2020,
    (avg_anxiety_2020 - avg_anxiety_2019) / avg_anxiety_2019 * 100   AS anxiety_pct_increase,
    avg_depression_2019,
    avg_depression_2020,
    (avg_depression_2020 - avg_depression_2019) / avg_depression_2019 * 100 AS depression_pct_increase
FROM pivoted;