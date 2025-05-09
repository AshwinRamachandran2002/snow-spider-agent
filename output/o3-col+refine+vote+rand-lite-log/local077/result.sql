WITH base AS (   -- keep only the required months and protect against divide-by-zero
    SELECT
        CAST(_year  AS INTEGER)              AS yr,
        CAST(_month AS INTEGER)              AS mo,
        month_year,
        interest_id,
        composition / NULLIF(index_value,0)  AS comp_to_idx
    FROM interest_metrics
    WHERE ( (_year = 2018 AND _month BETWEEN 9 AND 12)
             OR (_year = 2019 AND _month BETWEEN 1 AND 8) )
      AND index_value <> 0
),
avg_ratio AS (    -- average ratio for every interest in every month
    SELECT
        yr,
        mo,
        month_year,
        interest_id,
        AVG(comp_to_idx) AS avg_ratio
    FROM base
    GROUP BY yr, mo, month_year, interest_id
),
ranked AS (       -- pick the top-ranking interest each month
    SELECT
        *,
        RANK() OVER (PARTITION BY yr, mo ORDER BY avg_ratio DESC) AS rnk
    FROM avg_ratio
),
monthly_winner AS (
    SELECT
        yr,
        mo,
        month_year,
        interest_id,
        ROUND(avg_ratio,4) AS max_idx_comp
    FROM ranked
    WHERE rnk = 1
),
with_name AS (    -- attach readable interest names
    SELECT
        mw.*,
        im.interest_name
    FROM monthly_winner AS mw
    JOIN interest_map  AS im
      ON im.id = mw.interest_id
),
rolling_calc AS ( -- add 3-month rolling avg and previous winners
    SELECT
        yr,
        mo,
        month_year,
        interest_name                      AS top_interest,
        max_idx_comp                       AS max_idx_composition,
        ROUND(
            AVG(max_idx_comp)
            OVER (ORDER BY yr, mo
                  ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 4) AS rolling_3m_avg,
        LAG(interest_name,1) OVER (ORDER BY yr, mo)  AS prev1_interest,
        LAG(max_idx_comp,1) OVER (ORDER BY yr, mo)   AS prev1_max_idx,
        LAG(interest_name,2) OVER (ORDER BY yr, mo)  AS prev2_interest,
        LAG(max_idx_comp,2) OVER (ORDER BY yr, mo)   AS prev2_max_idx
    FROM with_name
)
SELECT
    month_year,
    top_interest,
    max_idx_composition,
    rolling_3m_avg,
    prev1_interest,
    prev1_max_idx,
    prev2_interest,
    prev2_max_idx
FROM rolling_calc
ORDER BY yr, mo;