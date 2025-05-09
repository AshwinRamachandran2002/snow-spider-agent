WITH "us_weekly" AS (
    SELECT
        TO_DATE("date")                             AS "dt",
        TRY_TO_NUMBER("symptom_anxiety")            AS "anxiety",
        TRY_TO_NUMBER("symptom_depression")         AS "depression"
    FROM COVID19_SYMPTOM_SEARCH.COVID19_SYMPTOM_SEARCH.SYMPTOM_SEARCH_COUNTRY_WEEKLY
    WHERE "country_region_code" = 'US'
),
"period_avgs" AS (
    SELECT
        CASE
            WHEN "dt" >= '2019-01-01' AND "dt" < '2020-01-01' THEN '2019_period'
            WHEN "dt" >= '2020-01-01' AND "dt" < '2021-01-01' THEN '2020_period'
        END                                          AS "period",
        AVG("anxiety")                               AS "avg_anxiety",
        AVG("depression")                            AS "avg_depression"
    FROM "us_weekly"
    WHERE "dt" >= '2019-01-01' AND "dt" < '2021-01-01'
    GROUP BY "period"
),
"pivot" AS (
    SELECT
        MAX(CASE WHEN "period" = '2019_period' THEN "avg_anxiety"    END) AS "anxiety_2019",
        MAX(CASE WHEN "period" = '2020_period' THEN "avg_anxiety"    END) AS "anxiety_2020",
        MAX(CASE WHEN "period" = '2019_period' THEN "avg_depression" END) AS "depression_2019",
        MAX(CASE WHEN "period" = '2020_period' THEN "avg_depression" END) AS "depression_2020"
    FROM "period_avgs"
)
SELECT
    "anxiety_2019",
    "anxiety_2020",
    (("anxiety_2020" - "anxiety_2019") / "anxiety_2019") * 100  AS "anxiety_percentage_increase",
    "depression_2019",
    "depression_2020",
    (("depression_2020" - "depression_2019") / "depression_2019") * 100 AS "depression_percentage_increase"
FROM "pivot";