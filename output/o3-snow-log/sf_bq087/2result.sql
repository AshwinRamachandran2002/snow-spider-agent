WITH weekly_county_vals AS (
    SELECT
        TO_DATE("date")                                     AS week_start,
        AVG(CAST("symptom_anosmia" AS FLOAT))               AS week_avg_anosmia
    FROM COVID19_SYMPTOM_SEARCH.COVID19_SYMPTOM_SEARCH.SYMPTOM_SEARCH_SUB_REGION_2_WEEKLY
    WHERE "country_region" = 'United States'
      AND "sub_region_1"  = 'New York'
      AND "sub_region_2" IN ('Bronx County',
                             'Queens County',
                             'Kings County',
                             'New York County',
                             'Richmond County')
      AND "date" BETWEEN '2019-01-01' AND '2020-12-31'
    GROUP BY TO_DATE("date")
),
period_avgs AS (
    SELECT
        CASE WHEN YEAR(week_start) = 2019 THEN '2019'
             WHEN YEAR(week_start) = 2020 THEN '2020' END   AS period,
        AVG(week_avg_anosmia)                               AS avg_weekly_anosmia
    FROM weekly_county_vals
    GROUP BY period
)
SELECT
    ROUND(
        (
            MAX(CASE WHEN period = '2020' THEN avg_weekly_anosmia END) -
            MAX(CASE WHEN period = '2019' THEN avg_weekly_anosmia END)
        )
        /
        MAX(CASE WHEN period = '2019' THEN avg_weekly_anosmia END)
        * 100
    , 4)                                                    AS percentage_change
FROM period_avgs;