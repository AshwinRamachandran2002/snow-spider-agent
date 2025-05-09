WITH events AS (
  SELECT
    t.user_pseudo_id,
    (SELECT ep.value.int_value FROM UNNEST(t.event_params) ep WHERE ep.key = 'ga_session_id') AS ga_session_id,
    t.event_timestamp,
    t.event_name,
    (SELECT ep.value.string_value FROM UNNEST(t.event_params) ep WHERE ep.key = 'page_title') AS page_title
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102` t
),
categories AS (
  SELECT LOWER(category) AS category FROM UNNEST([
    'Accessories',
    'Apparel',
    'Brands',
    'Campus Collection',
    'Drinkware',
    'Electronics',
    'Google Redesign',
    'Lifestyle',
    'Nest',
    'New 2015 Logo',
    'Notebooks Journals',
    'Office',
    'Shop by Brand',
    'Small Goods',
    'Stationery',
    'Wearables'
  ]) AS category
),
classified_events AS (
  SELECT
    *,
    CASE
      WHEN event_name = 'page_view' AND 
        EXISTS (
          SELECT 1 FROM categories c 
          WHERE LOWER(page_title) LIKE CONCAT('%', c.category, '%')
        ) THEN 'PLP'
      WHEN event_name = 'view_item' THEN 'PDP'
      ELSE NULL
    END AS event_type
  FROM events
),
session_event_times AS (
  SELECT
    user_pseudo_id,
    ga_session_id,
    MIN(IF(event_type = 'PLP', event_timestamp, NULL)) AS first_plp_time,
    MIN(IF(event_type = 'PDP', event_timestamp, NULL)) AS first_pdp_time
  FROM classified_events
  GROUP BY user_pseudo_id, ga_session_id
),
session_transition AS (
  SELECT
    *,
    CASE
      WHEN first_plp_time IS NOT NULL AND first_pdp_time IS NOT NULL AND first_plp_time < first_pdp_time
      THEN 1 ELSE 0
    END AS has_plp_pdp
  FROM session_event_times
)
SELECT
  ROUND(100 * SAFE_DIVIDE(
    SUM(has_plp_pdp),
    COUNT(*)
  ), 4) AS Percentage
FROM session_transition;