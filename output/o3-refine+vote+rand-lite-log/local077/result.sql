WITH filtered AS (
    /* 1.  Keep the required months and calculate average composition            */
    SELECT  CAST(_year  AS INTEGER)           AS yr,
            CAST(_month AS INTEGER)           AS mth,
            month_year,
            interest_id,
            (composition / index_value)       AS avg_comp
    FROM   interest_metrics
    WHERE  (CAST(_year AS INTEGER) = 2018 AND CAST(_month AS INTEGER) >= 9)
       OR  (CAST(_year AS INTEGER) = 2019 AND CAST(_month AS INTEGER) <= 8)
),
ranked AS (
    /* 2.  Rank interests inside each month by the average composition           */
    SELECT  *,
            ROW_NUMBER() OVER (PARTITION BY yr, mth
                               ORDER BY avg_comp DESC, interest_id) AS rn
    FROM    filtered
),
monthly_top AS (
    /* 3.  Keep only the top‑ranked interest for every month                     */
    SELECT  yr,
            mth,
            month_year,
            interest_id,
            avg_comp                       AS max_index_comp,
            (yr * 12 + mth)                AS month_idx
    FROM    ranked
    WHERE   rn = 1
)
SELECT  mt.month_year                                               AS date,
        im.interest_name,
        ROUND(mt.max_index_comp, 4)                                 AS max_index_comp,
        ROUND(AVG(mt.max_index_comp)
              OVER (ORDER BY mt.month_idx
                    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 4)   AS rolling_avg_3m,
        LAG(im.interest_name, 1) OVER (ORDER BY mt.month_idx)       AS prev1_interest_name,
        ROUND(LAG(mt.max_index_comp, 1)
              OVER (ORDER BY mt.month_idx), 4)                      AS prev1_max_index_comp,
        LAG(im.interest_name, 2) OVER (ORDER BY mt.month_idx)       AS prev2_interest_name,
        ROUND(LAG(mt.max_index_comp, 2)
              OVER (ORDER BY mt.month_idx), 4)                      AS prev2_max_index_comp
FROM    monthly_top  AS mt
JOIN    interest_map AS im
       ON im.id = mt.interest_id
ORDER BY mt.month_idx;