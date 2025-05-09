-- Distinct users who viewed the most‑visited page in January 2021
WITH jan_page_views AS (
  SELECT
    user_pseudo_id,
    -- extract the URL of the viewed page
    (
      SELECT ep.value.string_value
      FROM UNNEST(event_params) AS ep
      WHERE ep.key = 'page_location'
      LIMIT 1
    ) AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202101*`
  WHERE event_name = 'page_view'
    AND event_date BETWEEN '20210101' AND '20210131'
),
top_page AS (
  SELECT page_location
  FROM jan_page_views
  WHERE page_location IS NOT NULL
  GROUP BY page_location
  ORDER BY COUNT(*) DESC
  LIMIT 1          -- most frequently visited page
)
SELECT COUNT(DISTINCT user_pseudo_id) AS distinct_user_count
FROM jan_page_views
WHERE page_location = (SELECT page_location FROM top_page);