-- Distinct users who viewed the most-visited page in January 2021
WITH page_views AS (
  SELECT
    t.user_pseudo_id,
    ep.value.string_value AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202101*` AS t
  CROSS JOIN UNNEST(t.event_params) AS ep
  WHERE t.event_name = 'page_view'
    AND ep.key = 'page_location'
),
ranked_pages AS (
  SELECT
    page_location,
    COUNT(*) AS views,
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
  FROM page_views
  GROUP BY page_location
)
SELECT
  COUNT(DISTINCT pv.user_pseudo_id) AS distinct_users_on_top_page
FROM page_views AS pv
JOIN ranked_pages AS rp
  ON pv.page_location = rp.page_location
WHERE rp.rnk = 1;