WITH january_page_views AS (
  SELECT
    ep.value.string_value AS page_location,
    e.user_pseudo_id
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` AS e,
    UNNEST(e.event_params) AS ep
  WHERE
    _TABLE_SUFFIX LIKE '202101%'      -- January 2021 tables
    AND e.event_name = 'page_view'    -- only page_view events
    AND ep.key = 'page_location'      -- extract the page URL
),

top_page AS (
  SELECT
    page_location
  FROM
    january_page_views
  GROUP BY
    page_location
  ORDER BY
    COUNT(*) DESC                    -- most viewed page
  LIMIT 1
)

SELECT
  COUNT(DISTINCT user_pseudo_id) AS distinct_users_top_page
FROM
  january_page_views
WHERE
  page_location = (SELECT page_location FROM top_page);