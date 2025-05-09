WITH filtered AS (          -- 1. keep only Sep‑2018 to Aug‑2019
    SELECT
        CAST(_year  AS INTEGER)             AS yr ,
        CAST(_month AS INTEGER)             AS mn ,
        month_year,
        interest_id,
        composition / NULLIF(index_value,0) AS ratio
    FROM   interest_metrics
    WHERE  (CAST(_year AS INTEGER)=2018 AND CAST(_month AS INTEGER) BETWEEN 9 AND 12)
        OR (CAST(_year AS INTEGER)=2019 AND CAST(_month AS INTEGER) BETWEEN 1 AND 8)
),
avg_per_interest AS (       -- 2. monthly average of (composition/index_value)
    SELECT
        yr,
        mn,
        month_year,
        interest_id,
        AVG(ratio) AS avg_ratio
    FROM   filtered
    GROUP  BY yr, mn, month_year, interest_id
),
ranked AS (                 -- 3. pick the max‑ratio interest each month
    SELECT
        a.*,
        ROW_NUMBER() OVER (PARTITION BY yr, mn ORDER BY avg_ratio DESC) AS rn
    FROM   avg_per_interest a
),
month_top AS (              -- 4. enrich with interest name
    SELECT
        yr,
        mn,
        month_year,
        m.interest_name,
        avg_ratio AS max_index_composition
    FROM   ranked  r
    JOIN   interest_map m
           ON m.id = r.interest_id
    WHERE  rn = 1
),
final AS (                  -- 5. add 3‑month rolling avg & previous‑month info
    SELECT
        month_year                               AS date,
        interest_name,
        ROUND(max_index_composition,4)           AS max_index_composition,
        ROUND(AVG(max_index_composition)
              OVER(ORDER BY yr, mn
                   ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),4) AS rolling_avg_3m,
        LAG(interest_name,1)
              OVER(ORDER BY yr, mn)              AS prev1_interest_name,
        ROUND(LAG(max_index_composition,1)
              OVER(ORDER BY yr, mn),4)           AS prev1_max_index_composition,
        LAG(interest_name,2)
              OVER(ORDER BY yr, mn)              AS prev2_interest_name,
        ROUND(LAG(max_index_composition,2)
              OVER(ORDER BY yr, mn),4)           AS prev2_max_index_composition
    FROM   month_top
)
SELECT *
FROM   final
ORDER  BY substr(date,4,4), substr(date,1,2);   -- ensures chronological order