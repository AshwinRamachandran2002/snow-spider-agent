WITH filtered AS (
    SELECT
        TO_DATE("date")                              AS week_date,
        "symptom_anosmia"::FLOAT                    AS anosmia
    FROM COVID19_SYMPTOM_SEARCH.COVID19_SYMPTOM_SEARCH.SYMPTOM_SEARCH_SUB_REGION_2_WEEKLY
    WHERE "country_region_code" = 'US'
      AND "sub_region_1" = 'New York'
      AND "sub_region_2" IN ('Bronx County',
                             'Queens County',
                             'Kings County',
                             'New York County',
                             'Richmond County')
      AND TO_DATE("date") BETWEEN '2019-01-01' AND '2020-12-31'
),
period_avgs AS (
    SELECT
        CASE WHEN YEAR(week_date) = 2019 THEN '2019'
             WHEN YEAR(week_date) = 2020 THEN '2020' END AS period,
        AVG(anosmia) AS avg_anosmia
    FROM filtered
    WHERE anosmia IS NOT NULL
    GROUP BY period
)
SELECT
    ((p2020.avg_anosmia - p2019.avg_anosmia) / p2019.avg_anosmia) * 100 AS percentage_change
FROM
    (SELECT avg_anosmia FROM period_avgs WHERE period = '2019') p2019,
    (SELECT avg_anosmia FROM period_avgs WHERE period = '2020') p2020;