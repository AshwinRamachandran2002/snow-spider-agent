/* 1.  Pull January‑2021 page‑view events and extract the URL that was viewed
   2.  Find the single most viewed page (highest number of page_view events)
   3.  Count how many distinct users saw that page at least once           */

WITH jan_page_views AS (
  SELECT
    ep.value.string_value AS page_location,
    e.user_pseudo_id
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202101*` AS e,
    UNNEST(e.event_params) AS ep
  WHERE
    e.event_name = 'page_view'          -- only page‑view events
    AND ep.key = 'page_location'        -- grab the page URL
    AND ep.value.string_value IS NOT NULL
),

most_visited_page AS (
  SELECT
    page_location
  FROM jan_page_views
  GROUP BY page_location
  ORDER BY COUNT(*) DESC                -- highest number of views
  LIMIT 1
)

SELECT
  COUNT(DISTINCT user_pseudo_id) AS distinct_users
FROM
  jan_page_views
WHERE
  page_location = (SELECT page_location FROM most_visited_page);