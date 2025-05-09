WITH page_views AS (
  -- Extract page_view events in January 2021 and pull the page URL
  SELECT
    user_pseudo_id,
    (SELECT ep.value.string_value
     FROM UNNEST(event_params) ep
     WHERE ep.key = 'page_location'
     LIMIT 1) AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202101*`
  WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210131'
    AND event_name = 'page_view'
),
most_visited AS (
  -- Find the single most‑visited page (by URL)
  SELECT page_location
  FROM page_views
  WHERE page_location IS NOT NULL
  GROUP BY page_location
  ORDER BY COUNT(*) DESC
  LIMIT 1
)
-- Count distinct users who viewed that page
SELECT COUNT(DISTINCT pv.user_pseudo_id) AS distinct_users
FROM page_views pv
JOIN most_visited mv
  ON pv.page_location = mv.page_location;