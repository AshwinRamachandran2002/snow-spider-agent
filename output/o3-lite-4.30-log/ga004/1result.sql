WITH december_events AS (
  SELECT user_pseudo_id, event_name FROM (
    SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201201`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201202`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201203`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201204`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201205`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201206`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201207`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201208`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201209`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201210`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201211`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201212`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201213`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201214`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201215`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201216`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201217`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201218`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201219`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201220`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201221`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201222`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201223`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201224`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201225`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201226`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201227`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201228`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201229`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201230`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201231`
  )
),
pageviews AS (
  SELECT
    user_pseudo_id,
    COUNTIF(event_name = 'page_view') AS pv
  FROM december_events
  GROUP BY user_pseudo_id
),
buyers AS (
  SELECT
    user_pseudo_id,
    MAX(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END) AS purchaser
  FROM december_events
  GROUP BY user_pseudo_id
),
avg_pv AS (
  SELECT
    purchaser,
    AVG(IFNULL(pv, 0)) AS avg_pageviews
  FROM buyers
  LEFT JOIN pageviews USING (user_pseudo_id)
  GROUP BY purchaser
)
SELECT
  ROUND(
    MAX(IF(purchaser = 1, avg_pageviews, NULL)) -
    MAX(IF(purchaser = 0, avg_pageviews, NULL)),
    4
  ) AS average_pageviews_difference
FROM avg_pv;