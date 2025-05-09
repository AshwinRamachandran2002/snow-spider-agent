WITH filtered AS (
    /* keep only Sep-2018 → Aug-2019 rows and build a
       YYYYMM key (ym) so months sort chronologically   */
    SELECT  "month_year",
            "interest_id",
            "composition",
            "index_value",
            CAST(substr("month_year",4,4) || substr("month_year",1,2) AS INTEGER) AS ym
    FROM    "interest_metrics"
    WHERE   "month_year" <> ''
      AND ( (substr("month_year",4,4)='2018' AND substr("month_year",1,2) >='09')
         OR (substr("month_year",4,4)='2019' AND substr("month_year",1,2) <='08') )
),
/* average composition (= composition / index_value) per interest each month */
monthly_avg AS (
    SELECT  "month_year",
            ym,
            "interest_id",
            ROUND(AVG("composition" / NULLIF("index_value",0)),4) AS avg_comp_idx
    FROM    filtered
    GROUP BY "month_year", ym, "interest_id"
),
/* pick the interest with the highest avg value each month */
monthly_max AS (
    SELECT  ma.*
    FROM    monthly_avg  AS ma
    JOIN   (SELECT "month_year", MAX(avg_comp_idx) AS mx
            FROM monthly_avg
            GROUP BY "month_year") AS mxs
      ON    ma."month_year" = mxs."month_year"
     AND    ma.avg_comp_idx = mxs.mx
),
/* add human-readable interest names */
named_max AS (
    SELECT  mm."month_year",
            mm.ym,
            mp."interest_name",
            mm.avg_comp_idx
    FROM    monthly_max AS mm
    LEFT JOIN "interest_map" AS mp
           ON mp."id" = mm."interest_id"
),
/* compute 3-month rolling average and bring in prior-month winners */
rolling_final AS (
    SELECT  nm.*,
            ROUND(AVG(nm.avg_comp_idx) OVER (
                     ORDER BY nm.ym
                     ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),4) AS rolling_avg_3m,
            LAG(nm.interest_name,1) OVER (ORDER BY nm.ym) AS interest_m1,
            LAG(nm.avg_comp_idx,1)  OVER (ORDER BY nm.ym) AS max_idx_m1,
            LAG(nm.interest_name,2) OVER (ORDER BY nm.ym) AS interest_m2,
            LAG(nm.avg_comp_idx,2)  OVER (ORDER BY nm.ym) AS max_idx_m2
    FROM    named_max AS nm
)
SELECT  "month_year"      AS "date",
        "interest_name"   AS "top_interest",
        avg_comp_idx      AS "max_idx_comp",
        rolling_avg_3m,
        interest_m1,      max_idx_m1,
        interest_m2,      max_idx_m2
FROM    rolling_final
ORDER BY ym;