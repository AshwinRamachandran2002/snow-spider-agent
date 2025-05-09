WITH filtered AS (
    /* keep only Sep‑2018 to Aug‑2019 and work out the “average composition” */
    SELECT 
        CAST(_year  AS INTEGER)  AS yr,
        CAST(_month AS INTEGER)  AS mo,
        month_year,
        interest_id,
        composition / NULLIF(index_value,0) AS avg_comp
    FROM interest_metrics
    WHERE (_year = 2018 AND _month >= 9)
       OR (_year = 2019 AND _month <= 8)
),
ranked AS (
    /* pick the interest with the highest avg_comp each month */
    SELECT  *,
            ROW_NUMBER() OVER (PARTITION BY yr, mo 
                               ORDER BY avg_comp DESC, interest_id) AS rn
    FROM filtered
),
monthly_max AS (
    SELECT  yr,
            mo,
            month_year,
            interest_id,
            avg_comp AS max_index_comp
    FROM ranked
    WHERE rn = 1
),
with_names AS (
    /* add the human‑readable interest name */
    SELECT  m.yr,
            m.mo,
            m.month_year,
            i.interest_name,
            m.max_index_comp
    FROM monthly_max m
    JOIN interest_map i
      ON i.id = m.interest_id
)
SELECT  month_year                                   AS date,
        interest_name                                AS top_interest,
        ROUND(max_index_comp,4)                      AS max_index_composition,
        ROUND(AVG(max_index_comp) OVER (
                  ORDER BY yr, mo 
                  ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),4)     AS rolling_avg_3m,
        LAG(interest_name,1)  OVER (ORDER BY yr, mo)               AS prev1_interest,
        ROUND(LAG(max_index_comp,1) OVER (ORDER BY yr, mo),4)      AS prev1_max_index_composition,
        LAG(interest_name,2)  OVER (ORDER BY yr, mo)               AS prev2_interest,
        ROUND(LAG(max_index_comp,2) OVER (ORDER BY yr, mo),4)      AS prev2_max_index_composition
FROM    with_names
ORDER BY yr, mo;