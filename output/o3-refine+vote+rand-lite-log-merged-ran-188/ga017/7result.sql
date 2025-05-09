WITH jan_page_views AS (
  SELECT
    user_pseudo_id,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) AS ep
       WHERE ep.key = 'page_location') AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202101*`
  WHERE _TABLE_SUFFIX BETWEEN '01' AND '31'          -- tables for 2021‑01‑01 … 2021‑01‑31
    AND event_name = 'page_view'                     -- only page‑view events
),
most_visited_page AS (                               -- find the page with the most views
  SELECT page_location
  FROM jan_page_views
  WHERE page_location IS NOT NULL
  GROUP BY page_location
  ORDER BY COUNT(*) DESC
  LIMIT 1
)
SELECT COUNT(DISTINCT user_pseudo_id) AS distinct_users
FROM jan_page_views
WHERE page_location = (SELECT page_location FROM most_visited_page);