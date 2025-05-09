WITH highest_priced_category AS (
  SELECT
    f.value:"item_category"::STRING AS item_category
  FROM
    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201130" t,
    LATERAL FLATTEN(input => t."ITEMS") f
  WHERE
    t."EVENT_NAME" = 'purchase'
    AND t."EVENT_DATE" = '20201130'
    AND f.value:"price"::FLOAT = (
      SELECT
        MAX(f2.value:"price"::FLOAT)
      FROM
        GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201130" t2,
        LATERAL FLATTEN(input => t2."ITEMS") f2
      WHERE
        t2."EVENT_NAME" = 'purchase'
        AND t2."EVENT_DATE" = '20201130'
        AND f2.value:"price"::FLOAT IS NOT NULL
    )
  LIMIT 1
),
transaction_details AS (
  SELECT
    t."ECOMMERCE":"transaction_id"::STRING AS transaction_id,
    SUM(f.value:"quantity"::INT) AS total_item_quantity,
    t."ECOMMERCE":"purchase_revenue_in_usd"::FLOAT AS purchase_revenue
  FROM
    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201130" t,
    LATERAL FLATTEN(input => t."ITEMS") f,
    highest_priced_category hpc
  WHERE
    t."EVENT_NAME" = 'purchase'
    AND t."EVENT_DATE" = '20201130'
    AND f.value:"item_category"::STRING = hpc.item_category
  GROUP BY
    transaction_id,
    purchase_revenue
)
SELECT
  transaction_id,
  total_item_quantity,
  ROUND(purchase_revenue, 4) AS purchase_revenue
FROM
  transaction_details
ORDER BY
  transaction_id;