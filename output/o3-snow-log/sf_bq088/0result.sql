/*----------------------------------------------------------
  Average weekly Google-search interest for “anxiety”
  and “depression” in the United States, and the percentage
  increase from the 2019 period (2019-01-01‒2019-12-31)
  to the 2020 period (2020-01-01‒2020-12-31)
----------------------------------------------------------*/
WITH us_weekly AS (
    SELECT
        /* Cast date text to DATE and symptom text to FLOAT */
        CAST("date"                 AS DATE)  AS dt,
        CAST("symptom_anxiety"      AS FLOAT) AS anxiety,
        CAST("symptom_depression"   AS FLOAT) AS depression
    FROM COVID19_SYMPTOM_SEARCH.COVID19_SYMPTOM_SEARCH."SYMPTOM_SEARCH_COUNTRY_WEEKLY"
    WHERE "country_region_code" = 'US'
          AND "date" >= '2019-01-01'
          AND "date" <  '2021-01-01'
),
period_avgs AS (
    SELECT
        /* 2019-calendar-year period */
        AVG(CASE WHEN dt < '2020-01-01' THEN anxiety    END) AS avg_anxiety_2019,
        AVG(CASE WHEN dt < '2020-01-01' THEN depression END) AS avg_depr_2019,

        /* 2020-calendar-year period */
        AVG(CASE WHEN dt >= '2020-01-01' THEN anxiety    END) AS avg_anxiety_2020,
        AVG(CASE WHEN dt >= '2020-01-01' THEN depression END) AS avg_depr_2020
    FROM us_weekly
)
SELECT
    /* average levels */
    avg_anxiety_2019           AS "AVG_ANXIETY_2019",
    avg_anxiety_2020           AS "AVG_ANXIETY_2020",
    avg_depr_2019              AS "AVG_DEPRESSION_2019",
    avg_depr_2020              AS "AVG_DEPRESSION_2020",

    /* percentage increase from 2019 → 2020 */
    (avg_anxiety_2020 - avg_anxiety_2019) / avg_anxiety_2019 * 100 
        AS "ANXIETY_PERCENT_INCREASE",
    (avg_depr_2020   - avg_depr_2019)   / avg_depr_2019   * 100 
        AS "DEPRESSION_PERCENT_INCREASE"
FROM period_avgs;