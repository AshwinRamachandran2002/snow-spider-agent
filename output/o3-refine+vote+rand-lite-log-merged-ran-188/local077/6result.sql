WITH base AS (               /* 1. limit required months and work out average composition */
    SELECT  CAST(_year AS INTEGER)   AS year ,
            CAST(_month AS INTEGER)  AS month ,
            month_year ,
            interest_id ,
            composition / index_value           AS avg_comp
    FROM   interest_metrics
    WHERE  (_year = 2018 AND _month BETWEEN 9 AND 12)
        OR (_year = 2019 AND _month BETWEEN 1 AND 8)
),
ranked AS (                  /* 2. pick the highest avg_comp each month */
    SELECT  *,
            ROW_NUMBER() OVER (PARTITION BY year,month
                               ORDER BY avg_comp DESC) AS rn
    FROM    base
),
top_month AS (               /* 3. keep only the monthly winner */
    SELECT  year,
            month,
            month_year,
            interest_id,
            avg_comp                      AS max_index_comp,
            year*12 + month               AS month_key
    FROM    ranked
    WHERE   rn = 1
),
top_with_name AS (           /* 4. attach interest names */
    SELECT  t.*,
            im.interest_name
    FROM    top_month t
    LEFT JOIN interest_map im
           ON im.id = t.interest_id
),
rolling AS (                 /* 5. compute 3‑month rolling average of the monthly winners */
    SELECT  *,
            ROW_NUMBER() OVER (ORDER BY year,month)                              AS seq_num,
            ROUND(AVG(max_index_comp) OVER (ORDER BY year,month 
                                             ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),4) 
                                                                                AS raw_roll_avg
    FROM    top_with_name
),
combined AS (                /* 6. add prior‑month and two‑months‑ago winners */
    SELECT  c.year,
            c.month,
            c.month_year                        AS date,
            c.interest_name,
            ROUND(c.max_index_comp,4)           AS max_index_comp,
            CASE WHEN c.seq_num>=3 THEN c.raw_roll_avg END  AS rolling_avg,
            p1.interest_name                    AS prev_month_interest,
            ROUND(p1.max_index_comp,4)          AS prev_month_max_index_comp,
            p2.interest_name                    AS two_months_ago_interest,
            ROUND(p2.max_index_comp,4)          AS two_months_ago_max_index_comp
    FROM    rolling  c
    LEFT JOIN rolling p1  ON p1.month_key = c.month_key - 1
    LEFT JOIN rolling p2  ON p2.month_key = c.month_key - 2
)
SELECT  date,
        interest_name,
        max_index_comp,
        rolling_avg,
        prev_month_interest,
        prev_month_max_index_comp,
        two_months_ago_interest,
        two_months_ago_max_index_comp
FROM    combined
ORDER BY year, month;