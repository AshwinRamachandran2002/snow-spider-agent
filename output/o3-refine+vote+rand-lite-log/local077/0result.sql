WITH monthly_interest AS (
    /* 1.  Calculate monthly average composition (= composition / index_value) 
          for each interest between Sep‑2018 and Aug‑2019                       */
    SELECT
        im._year,
        im._month,
        printf('%04d-%02d', im._year, im._month) AS month_key,   -- YYYY-MM
        im.interest_id,
        AVG(im.composition / im.index_value) AS avg_comp
    FROM interest_metrics AS im
    WHERE (im._year = 2018 AND im._month >= 9)
       OR (im._year = 2019 AND im._month <= 8)
    GROUP BY im._year, im._month, im.interest_id
), monthly_max AS (
    /* 2. Pick the interest with the highest avg_comp each month               */
    SELECT
        mi.month_key,
        imap.interest_name,
        mi.avg_comp AS max_index_comp
    FROM (
        SELECT
            month_key,
            interest_id,
            avg_comp,
            ROW_NUMBER() OVER (
                PARTITION BY month_key
                ORDER BY avg_comp DESC, interest_id     -- tie‑breaker
            ) AS rn
        FROM monthly_interest
    ) AS mi
    JOIN interest_map AS imap
      ON imap.id = mi.interest_id
    WHERE mi.rn = 1
), with_lags AS (
    /* 3. Add 1‑ and 2‑month lags + 3‑month rolling average                    */
    SELECT
        month_key,
        interest_name,
        max_index_comp,
        LAG(interest_name, 1)  OVER (ORDER BY month_key) AS prev1_interest,
        LAG(max_index_comp, 1) OVER (ORDER BY month_key) AS prev1_comp,
        LAG(interest_name, 2)  OVER (ORDER BY month_key) AS prev2_interest,
        LAG(max_index_comp, 2) OVER (ORDER BY month_key) AS prev2_comp,
        AVG(max_index_comp) 
           OVER (ORDER BY month_key ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) 
           AS rolling_avg_3m
    FROM monthly_max
)
SELECT
    month_key                    AS date,
    interest_name,
    ROUND(max_index_comp,   4)   AS max_index_comp,
    ROUND(rolling_avg_3m,   4)   AS rolling_average_3m,
    prev1_interest               AS prev_month_interest,
    ROUND(prev1_comp,       4)   AS prev_month_max_index_comp,
    prev2_interest               AS two_months_ago_interest,
    ROUND(prev2_comp,       4)   AS two_months_ago_max_index_comp
FROM with_lags
ORDER BY month_key;