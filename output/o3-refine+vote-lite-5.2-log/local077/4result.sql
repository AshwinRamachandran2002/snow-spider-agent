WITH filtered AS (
    SELECT
        CAST(_year AS INTEGER)  AS yr,
        CAST(_month AS INTEGER) AS mn,
        month_year,
        interest_id,
        composition,
        index_value,
        (composition/index_value)                    AS ratio
    FROM interest_metrics
    WHERE (_year = 2018 AND _month >= 9)
       OR (_year = 2019 AND _month <= 8)
),
avg_interest_month AS (
    SELECT
        yr,
        mn,
        month_year,
        interest_id,
        AVG(ratio)                                   AS avg_ratio
    FROM filtered
    GROUP BY yr, mn, month_year, interest_id
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY yr, mn
            ORDER BY avg_ratio DESC, interest_id
        )                                            AS rn
    FROM avg_interest_month
),
monthly_max AS (
    SELECT
        yr,
        mn,
        month_year,
        interest_id,
        avg_ratio                                    AS max_index_composition
    FROM ranked
    WHERE rn = 1
),
with_names AS (
    SELECT
        m.yr,
        m.mn,
        m.month_year,
        i.interest_name,
        m.max_index_composition
    FROM monthly_max m
    LEFT JOIN interest_map i
           ON i.id = m.interest_id
),
rolling_calc AS (
    SELECT
        *,
        ROUND(
            AVG(max_index_composition) OVER (
                ORDER BY yr, mn
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            ), 4
        )                                            AS rolling_avg_3_month,
        LAG(interest_name,1)               OVER (ORDER BY yr, mn) AS prev1_interest_name,
        LAG(max_index_composition,1)       OVER (ORDER BY yr, mn) AS prev1_max_index_composition,
        LAG(interest_name,2)               OVER (ORDER BY yr, mn) AS prev2_interest_name,
        LAG(max_index_composition,2)       OVER (ORDER BY yr, mn) AS prev2_max_index_composition
    FROM with_names
)
SELECT
    month_year                       AS date,
    interest_name                    AS current_top_interest,
    ROUND(max_index_composition,4)   AS max_index_composition,
    rolling_avg_3_month,
    prev1_interest_name,
    ROUND(prev1_max_index_composition,4) AS prev1_max_index_composition,
    prev2_interest_name,
    ROUND(prev2_max_index_composition,4) AS prev2_max_index_composition
FROM rolling_calc
ORDER BY yr, mn;