-- Task: List all customers who purchased the 'Google Navy Speckled Tee' in December 2020, including the quantity purchased.

WITH
  PurchaseEvents AS (
    SELECT user_pseudo_id,
           PARSE_JSON(items) AS items
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201201
    WHERE event_name = 'purchase'
    UNION ALL
    SELECT user_pseudo_id,
           PARSE_JSON(items) AS items
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201202
    WHERE event_name = 'purchase'
    UNION ALL
    -- Continue UNION ALL statements for each day in December 2020
    SELECT user_pseudo_id,
           PARSE_JSON(items) AS items
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201231
    WHERE event_name = 'purchase'
  )
SELECT
  user_pseudo_id,
  item.value:item_name::STRING AS item_name,
  item.value:quantity::STRING AS quantity
FROM
  PurchaseEvents,
  LATERAL FLATTEN(input => items) AS item
WHERE
  item_name = 'Google Navy Speckled Tee'
LIMIT 100;