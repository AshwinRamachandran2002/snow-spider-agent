WITH month_interest AS (
    SELECT
        "month_year",
        "interest_id",
        ROUND(AVG("composition" / NULLIF("index_value",0)),4) AS avg_comp
    FROM   "interest_metrics"
    WHERE  ( _year = 2018 AND _month BETWEEN 9 AND 12 )
       OR  ( _year = 2019 AND _month BETWEEN 1 AND 8 )
    GROUP  BY "month_year", "interest_id"
),
month_max AS (
    SELECT
        "month_year",
        "interest_id",
        avg_comp,
        ROW_NUMBER() OVER (PARTITION BY "month_year" ORDER BY avg_comp DESC) AS rn
    FROM   month_interest
),
final_max AS (
    SELECT
        "month_year",
        DATE(SUBSTR("month_year",4,4)||'-'||SUBSTR("month_year",1,2)||'-01') AS month_start,
        "interest_id",
        avg_comp AS max_index_comp
    FROM   month_max
    WHERE  rn = 1
),
rolling AS (
    SELECT
        fm.*,
        ROUND(
            AVG(fm.max_index_comp) OVER (
                ORDER BY fm.month_start
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            ),4
        ) AS rolling_avg_3mo_max
    FROM   final_max fm
),
lagged AS (
    SELECT
        r.*,
        LAG(r.interest_id,1)    OVER (ORDER BY r.month_start) AS lag1_id,
        LAG(r.max_index_comp,1) OVER (ORDER BY r.month_start) AS lag1_comp,
        LAG(r.interest_id,2)    OVER (ORDER BY r.month_start) AS lag2_id,
        LAG(r.max_index_comp,2) OVER (ORDER BY r.month_start) AS lag2_comp
    FROM   rolling r
)
SELECT
    l.month_year                                   AS date,
    im_now."interest_name"                         AS interest_name,
    ROUND(l.max_index_comp,4)                      AS max_index_composition,
    l.rolling_avg_3mo_max                          AS rolling_avg_3mo_max,
    im_l1."interest_name"                          AS last_month_interest_name,
    ROUND(l.lag1_comp,4)                           AS last_month_max_index_composition,
    im_l2."interest_name"                          AS two_months_ago_interest_name,
    ROUND(l.lag2_comp,4)                           AS two_months_ago_max_index_composition
FROM   lagged l
LEFT JOIN "interest_map" im_now ON im_now."id" = l."interest_id"
LEFT JOIN "interest_map" im_l1  ON im_l1."id"  = l."lag1_id"
LEFT JOIN "interest_map" im_l2  ON im_l2."id"  = l."lag2_id"
ORDER  BY l.month_start;