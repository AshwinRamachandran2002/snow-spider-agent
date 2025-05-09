WITH filtered AS (
    /* 1. keep the required months and create the average‑composition ratio           */
    SELECT
        CAST(_year  AS INTEGER)                                   AS yr,
        CAST(_month AS INTEGER)                                   AS mo,
        month_year,
        CAST(interest_id AS INTEGER)                              AS interest_id,
        composition,
        index_value,
        composition / NULLIF(index_value,0)                       AS avg_comp
    FROM   interest_metrics
    WHERE  (_year = 2018 AND _month >= 9)
       OR  (_year = 2019 AND _month <= 8)
),
max_per_month AS (
    /* 2. rank interests inside each month by the ratio and keep the best one         */
    SELECT
        yr, mo, month_year, interest_id, avg_comp,
        ROW_NUMBER() OVER (PARTITION BY yr,mo
                           ORDER BY avg_comp DESC, interest_id)   AS rn
    FROM   filtered
),
top_per_month AS (
    /* 3. the top (rn=1) interest for every month                                       */
    SELECT yr, mo, month_year, interest_id, avg_comp
    FROM   max_per_month
    WHERE  rn = 1
),
top_with_name AS (
    /* 4. attach the interest name                                                      */
    SELECT
        tpm.yr, tpm.mo, tpm.month_year,
        im.interest_name,
        tpm.avg_comp
    FROM   top_per_month tpm
    LEFT  JOIN interest_map im
           ON im.id = tpm.interest_id
),
rolling AS (
    /* 5. add 3‑month rolling avg + info from the prior 2 months                        */
    SELECT
        yr,
        mo,
        month_year                           AS date,
        interest_name,
        avg_comp                             AS max_index_comp,
        AVG(avg_comp)
          OVER (ORDER BY yr,mo
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)       AS rolling_avg_3m,
        LAG(interest_name,1)  OVER (ORDER BY yr,mo)             AS prev1_interest,
        LAG(avg_comp,1)       OVER (ORDER BY yr,mo)             AS prev1_max_index_comp,
        LAG(interest_name,2)  OVER (ORDER BY yr,mo)             AS prev2_interest,
        LAG(avg_comp,2)       OVER (ORDER BY yr,mo)             AS prev2_max_index_comp
    FROM   top_with_name
)
SELECT
    date,
    interest_name,
    ROUND(max_index_comp,      4) AS max_index_comp,
    ROUND(rolling_avg_3m,      4) AS rolling_avg_3m,
    prev1_interest,
    ROUND(prev1_max_index_comp,4) AS prev1_max_index_comp,
    prev2_interest,
    ROUND(prev2_max_index_comp,4) AS prev2_max_index_comp
FROM   rolling
ORDER BY yr, mo;