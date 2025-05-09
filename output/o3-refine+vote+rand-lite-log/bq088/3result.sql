WITH us_weekly AS (
    SELECT
        PARSE_DATE('%Y-%m-%d', `date`)                    AS dt,
        CAST(symptom_anxiety    AS FLOAT64)               AS anxiety,
        CAST(symptom_depression AS FLOAT64)               AS depression
    FROM `bigquery-public-data.covid19_symptom_search.symptom_search_country_weekly`
    WHERE country_region_code = 'US'
          -- keep only rows needed for both periods
          AND `date` >= '2019-01-01'
          AND `date` <  '2021-01-01'
),
tagged AS (
    SELECT
        CASE
            WHEN dt < DATE '2020-01-01' THEN '2019_period'   -- 2019‑01‑01  to 2019‑12‑31
            ELSE '2020_period'                               -- 2020‑01‑01  to 2020‑12‑31
        END                                  AS period,
        anxiety,
        depression
    FROM us_weekly
)
SELECT
    symptom,
    ROUND(avg_2019 , 4) AS avg_2019,
    ROUND(avg_2020 , 4) AS avg_2020,
    ROUND( (avg_2020 - avg_2019) * 100 / avg_2019 , 4) AS pct_increase
FROM (
    SELECT
        'anxiety'   AS symptom,
        AVG(CASE WHEN period = '2019_period' THEN anxiety    END) AS avg_2019,
        AVG(CASE WHEN period = '2020_period' THEN anxiety    END) AS avg_2020
    FROM tagged

    UNION ALL

    SELECT
        'depression',
        AVG(CASE WHEN period = '2019_period' THEN depression END) AS avg_2019,
        AVG(CASE WHEN period = '2020_period' THEN depression END) AS avg_2020
    FROM tagged
);