WITH monthly_avg AS (
    /* 1. average composition per interest each month */
    SELECT
        "month_year",
        "interest_id",
        ROUND(AVG("composition" / NULLIF("index_value",0)),4) AS avg_comp
    FROM "interest_metrics"
    /* window: Sep-2018 (201809) to Aug-2019 (201908) */
    WHERE (CAST(SUBSTR("month_year",4,4) AS INTEGER) * 100
           + CAST(SUBSTR("month_year",1,2) AS INTEGER)) BETWEEN 201809 AND 201908
    GROUP BY "month_year","interest_id"
),
monthly_max AS (
    /* 2. highest-avg interest each month */
    SELECT
        "month_year",
        "interest_id",
        avg_comp                                  AS max_index_comp,
        RANK() OVER (PARTITION BY "month_year"
                     ORDER BY avg_comp DESC)      AS rnk
    FROM monthly_avg
),
top_monthly AS (
    /* 3. attach interest names – keep only the rank-1 rows */
    SELECT
        mm."month_year",
        im."interest_name",
        mm."max_index_comp"
    FROM monthly_max AS mm
    JOIN "interest_map" AS im
      ON im."id" = mm."interest_id"
    WHERE mm.rnk = 1
)
SELECT
    tm."month_year"                                                AS "date",
    tm."interest_name"                                             AS "top_interest",
    tm."max_index_comp"                                            AS "max_index_composition",
    /* 4. 3-month rolling average of monthly max comps */
    ROUND(
        AVG(tm."max_index_comp") OVER (ORDER BY tm."month_year"
                                       ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),
        4
    )                                                              AS "rolling_3m_avg",
    /* 5. prior-month and two-months-ago leaders */
    LAG(tm."interest_name",1)  OVER (ORDER BY tm."month_year")     AS "top_interest_m-1",
    LAG(tm."max_index_comp",1) OVER (ORDER BY tm."month_year")     AS "max_comp_m-1",
    LAG(tm."interest_name",2)  OVER (ORDER BY tm."month_year")     AS "top_interest_m-2",
    LAG(tm."max_index_comp",2) OVER (ORDER BY tm."month_year")     AS "max_comp_m-2"
FROM   top_monthly AS tm
/* numeric ordering guarantees Sep-2018 → Aug-2019 sequence */
ORDER  BY (CAST(SUBSTR(tm."month_year",4,4) AS INTEGER) * 100
           + CAST(SUBSTR(tm."month_year",1,2) AS INTEGER));