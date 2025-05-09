WITH dec_paths AS (
  SELECT
    REGEXP_REPLACE(
      REGEXP_EXTRACT(
        (SELECT p.value.string_value
         FROM UNNEST(event_params) AS p
         WHERE p.key = 'page_location'
         LIMIT 1),
        r'https?://shop\.googlemerchandisestore\.com([^?#]*)'),
      r'/{2,}', '/') AS clean_path
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE event_name = 'page_view'
),
agg AS (
  SELECT
    clean_path,
    COUNT(*) AS page_views,
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
  FROM dec_paths
  WHERE clean_path IS NOT NULL
  GROUP BY clean_path
)
SELECT
  clean_path   AS second_most_viewed_page,
  page_views   AS total_page_views
FROM agg
WHERE rnk = 2;