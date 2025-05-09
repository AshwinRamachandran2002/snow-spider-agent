WITH us_weekly AS (
    SELECT 
        TO_DATE("date")                                          AS week_date ,
        TRY_TO_NUMBER("symptom_anxiety")                         AS anxiety ,
        TRY_TO_NUMBER("symptom_depression")                      AS depression
    FROM COVID19_SYMPTOM_SEARCH.COVID19_SYMPTOM_SEARCH."SYMPTOM_SEARCH_COUNTRY_WEEKLY"
    WHERE "country_region_code" = 'US'
      AND "date" >= '2019-01-01'
      AND "date" <  '2021-01-01'
),
period_avg AS (
    SELECT
        CASE
            WHEN week_date >= '2019-01-01' AND week_date < '2020-01-01' THEN '2019'
            ELSE '2020'
        END                                                     AS period ,
        AVG(anxiety)                                            AS avg_anxiety ,
        AVG(depression)                                         AS avg_depression
    FROM us_weekly
    GROUP BY period
)
SELECT
    MAX(CASE WHEN period = '2019' THEN avg_anxiety    END)      AS avg_anxiety_2019 ,
    MAX(CASE WHEN period = '2020' THEN avg_anxiety    END)      AS avg_anxiety_2020 ,
    ( MAX(CASE WHEN period = '2020' THEN avg_anxiety END)
      - MAX(CASE WHEN period = '2019' THEN avg_anxiety END) )
      / NULLIF( MAX(CASE WHEN period = '2019' THEN avg_anxiety END) , 0 ) * 100  AS anxiety_pct_increase ,

    MAX(CASE WHEN period = '2019' THEN avg_depression END)      AS avg_depression_2019 ,
    MAX(CASE WHEN period = '2020' THEN avg_depression END)      AS avg_depression_2020 ,
    ( MAX(CASE WHEN period = '2020' THEN avg_depression END)
      - MAX(CASE WHEN period = '2019' THEN avg_depression END) )
      / NULLIF( MAX(CASE WHEN period = '2019' THEN avg_depression END) , 0 ) * 100  AS depression_pct_increase
FROM period_avg;