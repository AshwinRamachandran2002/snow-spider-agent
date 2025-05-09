WITH page_views AS (
  SELECT
    param.value.string_value AS page_title,
    COUNT(*) AS total_views
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
    UNNEST(`event_params`) AS param
  WHERE
    `_TABLE_SUFFIX` BETWEEN '20210101' AND '20210131'
    AND `event_name` = 'page_view'
    AND param.key = 'page_title'
    AND param.value.string_value IS NOT NULL
  GROUP BY page_title
),
most_viewed_page AS (
  SELECT page_title
  FROM page_views
  ORDER BY total_views DESC
  LIMIT 1
)
SELECT COUNT(DISTINCT `user_pseudo_id`) AS Number_of_Distinct_Users
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
  UNNEST(`event_params`) AS param
WHERE
  `_TABLE_SUFFIX` BETWEEN '20210101' AND '20210131'
  AND `event_name` = 'page_view'
  AND param.key = 'page_title'
  AND param.value.string_value = (SELECT page_title FROM most_viewed_page);