WITH december AS (
  -- Pull every December-2020 page_view and derive a tidy path
  SELECT
    REGEXP_REPLACE(
      REGEXP_REPLACE(
        REGEXP_REPLACE(ep.value.string_value,
                       r'^https?://shop\.googlemerchandisestore\.com', ''),
        r'/{2,}', '/'),
      r'[\?#].*', '')                           AS clean_path
  FROM  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*` AS ev
  JOIN  UNNEST(ev.event_params) AS ep
  WHERE ev.event_name = 'page_view'
    AND ep.key       = 'page_location'
    AND ep.value.string_value LIKE 'https://shop.googlemerchandisestore.com%'
),
ranked AS (
  -- Count page views per path and rank them
  SELECT
    clean_path,
    COUNT(*) AS page_views,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
  FROM december
  GROUP BY clean_path
)
-- Return the page with the 2nd-highest total views
SELECT clean_path AS second_most_viewed_page
FROM   ranked
WHERE  rnk = 2;