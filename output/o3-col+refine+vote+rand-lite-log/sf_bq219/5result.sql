WITH state_month AS (   -- total liters sold statewide each month (complete months only)
    SELECT 
        DATE_TRUNC('month', "date")                          AS month,
        SUM("volume_sold_liters")                           AS state_liters
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
    WHERE "date" >= '2022-01-01'
      AND "date" < DATE_TRUNC('month', CURRENT_DATE)        -- exclude current (partial) month
    GROUP BY 1
), cat_month AS (        -- each category’s share of statewide volume each month
    SELECT
        DATE_TRUNC('month', s."date")                       AS month,
        s."category_name",
        SUM(s."volume_sold_liters") / st.state_liters       AS pct_state
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES s
    JOIN state_month st
      ON DATE_TRUNC('month', s."date") = st.month
    WHERE s."date" >= '2022-01-01'
      AND s."date" < DATE_TRUNC('month', CURRENT_DATE)
    GROUP BY 1, 2, st.state_liters
), qualified AS (        -- categories present ≥24 months and averaging ≥1 % share
    SELECT 
        "category_name"
    FROM cat_month
    GROUP BY 1
    HAVING COUNT(*) >= 24
       AND AVG(pct_state) >= 0.01
)
SELECT
    c1."category_name"                     AS category_1,
    c2."category_name"                     AS category_2,
    CORR(c1.pct_state, c2.pct_state)       AS pearson_corr
FROM cat_month c1
JOIN cat_month c2
  ON c1.month = c2.month
JOIN qualified q1
  ON c1."category_name" = q1."category_name"
JOIN qualified q2
  ON c2."category_name" = q2."category_name"
WHERE c1."category_name" < c2."category_name"  -- avoid duplicates & self-pairs
GROUP BY category_1, category_2
ORDER BY pearson_corr ASC
LIMIT 1;