WITH per_interest AS (        -- ① average (composition / index_value) per interest‑month
    SELECT  ("_year" * 100 + "_month")            AS yr_mo,
            "month_year",
            "interest_id",
            AVG("composition" / NULLIF("index_value",0)) AS avg_comp_ratio
    FROM    "interest_metrics"
    WHERE   (("_year" = 2018 AND "_month" >= 9)
          OR ("_year" = 2019 AND "_month" <= 8))
    GROUP BY yr_mo, "month_year", "interest_id"
),
monthly_leader AS (           -- ② pick the interest with the max ratio each month
    SELECT  *,
            ROW_NUMBER() OVER (PARTITION BY yr_mo
                               ORDER BY avg_comp_ratio DESC, "interest_id") AS rn
    FROM    per_interest
),
max_only AS (                  -- ③ keep only the monthly winner
    SELECT  yr_mo,
            "month_year",
            "interest_id",
            avg_comp_ratio
    FROM    monthly_leader
    WHERE   rn = 1
)
SELECT  m."month_year"                                           AS "date",
        im."interest_name",
        ROUND(m.avg_comp_ratio,4)                                AS "max_index_composition",
        ROUND(AVG(m.avg_comp_ratio) OVER (ORDER BY m.yr_mo
                           ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),4)
                                                                AS "rolling_avg_3_month",
        LAG(im."interest_name",1) OVER (ORDER BY m.yr_mo)        AS "prev_month_interest",
        ROUND(LAG(m.avg_comp_ratio,1) OVER (ORDER BY m.yr_mo),4) AS "prev_month_max_comp",
        LAG(im."interest_name",2) OVER (ORDER BY m.yr_mo)        AS "two_months_ago_interest",
        ROUND(LAG(m.avg_comp_ratio,2) OVER (ORDER BY m.yr_mo),4) AS "two_months_ago_max_comp"
FROM    max_only AS m
JOIN    "interest_map" AS im
        ON im."id" = m."interest_id"
ORDER BY m.yr_mo;