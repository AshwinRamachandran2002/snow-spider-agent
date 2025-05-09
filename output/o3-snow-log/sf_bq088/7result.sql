WITH us_weekly AS (
    SELECT
        TO_DATE("date")                         AS week_date,
        TRY_TO_DOUBLE("symptom_anxiety")        AS anxiety,
        TRY_TO_DOUBLE("symptom_depression")     AS depression
    FROM COVID19_SYMPTOM_SEARCH.COVID19_SYMPTOM_SEARCH.SYMPTOM_SEARCH_COUNTRY_WEEKLY
    WHERE "country_region_code" = 'US'
)
SELECT
    /* average levels Jan-1-2019  – Dec-31-2019 */
    AVG(CASE WHEN week_date >= '2019-01-01' AND week_date < '2020-01-01' THEN anxiety END)     AS avg_anxiety_2019,
    AVG(CASE WHEN week_date >= '2019-01-01' AND week_date < '2020-01-01' THEN depression END)  AS avg_depression_2019,

    /* average levels Jan-1-2020  – Dec-31-2020 */
    AVG(CASE WHEN week_date >= '2020-01-01' AND week_date < '2021-01-01' THEN anxiety END)     AS avg_anxiety_2020,
    AVG(CASE WHEN week_date >= '2020-01-01' AND week_date < '2021-01-01' THEN depression END)  AS avg_depression_2020,

    /* percentage increase from 2019 period to 2020 period */
    (AVG(CASE WHEN week_date >= '2020-01-01' AND week_date < '2021-01-01' THEN anxiety END)
     - AVG(CASE WHEN week_date >= '2019-01-01' AND week_date < '2020-01-01' THEN anxiety END))
     / NULLIF(AVG(CASE WHEN week_date >= '2019-01-01' AND week_date < '2020-01-01' THEN anxiety END),0) * 100
        AS pct_increase_anxiety,

    (AVG(CASE WHEN week_date >= '2020-01-01' AND week_date < '2021-01-01' THEN depression END)
     - AVG(CASE WHEN week_date >= '2019-01-01' AND week_date < '2020-01-01' THEN depression END))
     / NULLIF(AVG(CASE WHEN week_date >= '2019-01-01' AND week_date < '2020-01-01' THEN depression END),0) * 100
        AS pct_increase_depression
FROM us_weekly;