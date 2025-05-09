WITH filtered_sales AS (
    -- keep only France’s 2019‑2020 sales that satisfy the promo & channel restrictions
    SELECT  s.prod_id,
            s.amount_sold,
            s.time_id
    FROM    sales        AS s
    JOIN    customers    AS cu  ON cu.cust_id = s.cust_id
    JOIN    countries    AS co  ON co.country_id = cu.country_id
    JOIN    promotions   AS pr  ON pr.promo_id  = s.promo_id
    JOIN    channels     AS ch  ON ch.channel_id = s.channel_id
    WHERE   co.country_name  = 'France'
      AND   pr.promo_total_id = 1
      AND   ch.channel_total_id = 1
      AND   strftime('%Y', s.time_id) IN ('2019','2020')
),
monthly_totals AS (
    -- monthly sales per product for 2019 and 2020
    SELECT  prod_id,
            CAST(strftime('%m', time_id) AS INTEGER) AS month,
            SUM(CASE WHEN strftime('%Y', time_id)='2019' THEN amount_sold END) AS amt_2019,
            SUM(CASE WHEN strftime('%Y', time_id)='2020' THEN amount_sold END) AS amt_2020
    FROM    filtered_sales
    GROUP BY prod_id, month
),
projected_2021_local AS (
    -- apply growth rate (= Δ/2019) to 2020 amount to project 2021
    SELECT  prod_id,
            month,
            CASE
                WHEN amt_2019 IS NOT NULL
                 AND amt_2019>0
                 AND amt_2020 IS NOT NULL
                THEN amt_2020 * (1 + (amt_2020 - amt_2019) * 1.0 / amt_2019)
            END AS proj_local_currency
    FROM    monthly_totals
),
proj_usd AS (
    -- convert each projection to USD with 2021 FX rates
    SELECT  p.prod_id,
            p.month,
            p.proj_local_currency * fx.to_us AS proj_usd
    FROM    projected_2021_local AS p
    JOIN    currency            AS fx
           ON fx.country = 'France'
          AND fx.year    = 2021
          AND fx.month   = p.month
    WHERE   p.proj_local_currency IS NOT NULL
)
-- final average per month across all products
SELECT  month,
        ROUND(AVG(proj_usd), 4) AS avg_projected_sales_usd
FROM    proj_usd
GROUP BY month
ORDER BY month;