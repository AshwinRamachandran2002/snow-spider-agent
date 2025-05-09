WITH base AS (
    /* 1. limit to Sep‑2018 … Aug‑2019 and calculate average composition  */
    SELECT
        CAST(_month AS INTEGER)      AS month_num,
        CAST(_year  AS INTEGER)      AS year_num,
        month_year,
        interest_id,
        composition / index_value    AS avg_comp
    FROM interest_metrics
    WHERE (CAST(_year AS INTEGER) = 2018 AND CAST(_month AS INTEGER) >= 9)
       OR (CAST(_year AS INTEGER) = 2019 AND CAST(_month AS INTEGER) <= 8)
),
monthly_ranked AS (
    /* 2. pick the highest‑avg_comp interest for each month               */
    SELECT
        month_num,
        year_num,
        month_year,
        interest_id,
        avg_comp,
        ROW_NUMBER() OVER (
            PARTITION BY month_year
            ORDER BY avg_comp DESC
        ) AS rn
    FROM base
),
monthly_max AS (
    SELECT
        month_num,
        year_num,
        month_year,
        year_num * 100 + month_num          AS period_code,   -- for easy ordering
        interest_id,
        avg_comp                            AS max_index_comp
    FROM monthly_ranked
    WHERE rn = 1
),
monthly_max_named AS (
    /* 3. add the interest name                                            */
    SELECT
        period_code,
        month_year,
        COALESCE(im.interest_name,'unknown')       AS interest_name,
        ROUND(max_index_comp,4)                    AS max_index_comp
    FROM monthly_max mm
    LEFT JOIN interest_map im
           ON im.id = CAST(mm.interest_id AS INTEGER)
),
result AS (
    /* 4. rolling 3‑month average + look‑backs for 1 and 2 months           */
    SELECT
        month_year                                AS date,
        interest_name,
        max_index_comp                            AS max_index_composition,
        ROUND(
            AVG(max_index_comp) OVER (
                ORDER BY period_code
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            )
        ,4)                                       AS rolling_avg_3_month,
        LAG(interest_name,1) OVER (ORDER BY period_code)  AS prev1_interest_name,
        ROUND(LAG(max_index_comp,1) OVER (ORDER BY period_code),4)
                                                   AS prev1_max_index_composition,
        LAG(interest_name,2) OVER (ORDER BY period_code)  AS prev2_interest_name,
        ROUND(LAG(max_index_comp,2) OVER (ORDER BY period_code),4)
                                                   AS prev2_max_index_composition
    FROM monthly_max_named
)
SELECT *
FROM result
ORDER BY substr(date,4,4)*100 + substr(date,1,2);   -- chronological output