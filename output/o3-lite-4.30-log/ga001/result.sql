WITH december_events AS (
    SELECT event_name,
           ecommerce.transaction_id AS transaction_id,
           items
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201201`
    UNION ALL SELECT event_name, ecommerce.transaction_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201202`
    UNION ALL SELECT event_name, ecommerce.transaction_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201203`
    UNION ALL SELECT event_name, ecommerce.transaction_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201204`
    UNION ALL SELECT event_name, ecommerce.transaction_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201205`
    UNION ALL SELECT event_name, ecommerce.transaction_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201206`
    UNION ALL SELECT event_name, ecommerce.transaction_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201207`
    UNION ALL SELECT event_name, ecommerce.transaction_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201208`
    UNION ALL SELECT event_name, ecommerce.transaction_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201209`
    UNION ALL SELECT event_name, ecommerce.transaction_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201210`
    UNION ALL SELECT event_name, ecommerce.transaction_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201211`
    UNION ALL SELECT event_name, ecommerce.transaction_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201212`
    UNION ALL SELECT event_name, ecommerce.transaction_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201213`
    UNION ALL SELECT event_name, ecommerce.transaction_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201214`
    UNION ALL SELECT event_name, ecommerce.transaction_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201215`
    UNION ALL SELECT event_name, ecommerce.transaction_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201216`
    UNION ALL SELECT event_name, ecommerce.transaction_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201217`
    UNION ALL SELECT event_name, ecommerce.transaction_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201218`
    UNION ALL SELECT event_name, ecommerce.transaction_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201219`
    UNION ALL SELECT event_name, ecommerce.transaction_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201220`
    UNION ALL SELECT event_name, ecommerce.transaction_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201221`
    UNION ALL SELECT event_name, ecommerce.transaction_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201222`
    UNION ALL SELECT event_name, ecommerce.transaction_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201223`
    UNION ALL SELECT event_name, ecommerce.transaction_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201224`
    UNION ALL SELECT event_name, ecommerce.transaction_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201225`
    UNION ALL SELECT event_name, ecommerce.transaction_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201226`
    UNION ALL SELECT event_name, ecommerce.transaction_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201227`
    UNION ALL SELECT event_name, ecommerce.transaction_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201228`
    UNION ALL SELECT event_name, ecommerce.transaction_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201229`
    UNION ALL SELECT event_name, ecommerce.transaction_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201230`
    UNION ALL SELECT event_name, ecommerce.transaction_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201231`
),
tee_transactions AS (
    SELECT DISTINCT transaction_id
    FROM december_events,
         UNNEST(items) AS it
    WHERE event_name = 'purchase'
      AND it.item_name = 'Google Navy Speckled Tee'
)
SELECT
    other.item_name     AS product_name,
    SUM(CAST(other.quantity AS NUMERIC)) AS total_quantity
FROM december_events e
JOIN tee_transactions t
  ON e.transaction_id = t.transaction_id
JOIN UNNEST(e.items) AS other
WHERE e.event_name = 'purchase'
  AND other.item_name <> 'Google Navy Speckled Tee'
GROUP BY product_name
ORDER BY total_quantity DESC, product_name
LIMIT 1;