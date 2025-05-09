/*  What other product was bought most (by total quantity) in the same
    transactions where “Google Navy Speckled Tee” was purchased
    during December 2020.                                              */

WITH december_purchases AS (
  SELECT
    ecommerce.transaction_id AS transaction_id,
    items
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE
    event_name = 'purchase'
    AND ecommerce.transaction_id IS NOT NULL
),

-- Transactions that include the Google Navy Speckled Tee
tee_tx AS (
  SELECT DISTINCT transaction_id
  FROM december_purchases,
       UNNEST(items) AS itm
  WHERE
    LOWER(itm.item_name) LIKE '%google navy speckled tee%'
),

-- All other items bought in those transactions
co_items AS (
  SELECT
    other.item_name                         AS item_name,
    SUM(other.quantity)                     AS total_quantity
  FROM december_purchases p
  JOIN tee_tx t
    ON p.transaction_id = t.transaction_id
  CROSS JOIN UNNEST(p.items) AS other
  WHERE
    LOWER(other.item_name) NOT LIKE '%google navy speckled tee%'
  GROUP BY
    other.item_name
)

SELECT
  item_name,
  total_quantity
FROM
  co_items
ORDER BY
  total_quantity DESC,
  item_name
LIMIT 1;