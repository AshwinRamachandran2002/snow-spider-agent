-- Task: Could you provide the number of page views and purchase events per user per day in November 2020?
SELECT
  user_pseudo_id,
  PARSE_DATE('%Y%m%d', event_date) AS event_date,
  COUNTIF(event_name = 'page_view') AS page_view_count,
  COUNTIF(event_name = 'purchase') AS purchase_event_count
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
GROUP BY 1, 2;