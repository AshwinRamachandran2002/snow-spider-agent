WITH weekly_us AS (
    SELECT
        TO_DATE("date")                             AS "dt",
        TRY_TO_NUMBER("symptom_anxiety")            AS "anxiety",
        TRY_TO_NUMBER("symptom_depression")         AS "depression"
    FROM COVID19_SYMPTOM_SEARCH.COVID19_SYMPTOM_SEARCH."SYMPTOM_SEARCH_COUNTRY_WEEKLY"
    WHERE "country_region_code" = 'US'
      AND "sub_region_1" IS NULL
      AND "sub_region_2" IS NULL
      AND TO_DATE("date") >= '2019-01-01'
      AND TO_DATE("date") <  '2021-01-01'
), period_avgs AS (
    SELECT
        CASE 
            WHEN "dt" >= '2019-01-01' AND "dt" < '2020-01-01' THEN '2019'
            WHEN "dt" >= '2020-01-01' AND "dt" < '2021-01-01' THEN '2020'
        END                                          AS "period",
        AVG("anxiety")                               AS "avg_anxiety",
        AVG("depression")                            AS "avg_depression"
    FROM weekly_us
    GROUP BY "period"
)
-- assemble final report
SELECT 
    'anxiety'                                        AS "symptom",
    MAX(CASE WHEN "period" = '2019' THEN "avg_anxiety" END)  AS "avg_2019",
    MAX(CASE WHEN "period" = '2020' THEN "avg_anxiety" END)  AS "avg_2020",
    ( MAX(CASE WHEN "period" = '2020' THEN "avg_anxiety" END)
      - MAX(CASE WHEN "period" = '2019' THEN "avg_anxiety" END) )
      / NULLIF( MAX(CASE WHEN "period" = '2019' THEN "avg_anxiety" END), 0) * 100
                                                     AS "pct_increase"
FROM period_avgs

UNION ALL

SELECT 
    'depression'                                     AS "symptom",
    MAX(CASE WHEN "period" = '2019' THEN "avg_depression" END) AS "avg_2019",
    MAX(CASE WHEN "period" = '2020' THEN "avg_depression" END) AS "avg_2020",
    ( MAX(CASE WHEN "period" = '2020' THEN "avg_depression" END)
      - MAX(CASE WHEN "period" = '2019' THEN "avg_depression" END) )
      / NULLIF( MAX(CASE WHEN "period" = '2019' THEN "avg_depression" END), 0) * 100
                                                     AS "pct_increase"
FROM period_avgs;