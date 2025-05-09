WITH page_views AS (
  -- All page_view events in January‑2021 with their page URL
  SELECT
    user_pseudo_id,
    -- pull the page URL stored in the event parameter "page_location"
    (SELECT ep.value.string_value
     FROM UNNEST(event_params) AS ep
     WHERE ep.key = 'page_location') AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202101*`
  WHERE event_name = 'page_view'
),

-- Identify the single most visited page (by number of page_view events)
top_page AS (
  SELECT page_location
  FROM page_views
  WHERE page_location IS NOT NULL
  GROUP BY page_location
  ORDER BY COUNT(*) DESC
  LIMIT 1
)

-- Count distinct users that viewed that page
SELECT
  COUNT(DISTINCT user_pseudo_id) AS distinct_users
FROM page_views
WHERE page_location = (SELECT page_location FROM top_page);