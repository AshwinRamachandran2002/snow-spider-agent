-- 2nd‑highest page‑viewed cleaned URL path on shop.googlemerchandisestore.com for December 2020
WITH dec_pageviews AS (
  SELECT
    -- clean the path: keep only the path part, default to "/", collapse duplicate "/"
    REGEXP_REPLACE(
      IFNULL(
        NULLIF(
          REGEXP_EXTRACT(  -- take path (everything after the host, before ? or #)
            ep.value.string_value,
            r'^https?://shop\.googlemerchandisestore\.com(/[^?#]*)?'
          ),
          ''
        ),
        '/'
      ),
      r'/+',
      '/'
    ) AS page_path
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`,
       UNNEST(event_params) AS ep
  WHERE
    event_name = 'page_view'
    AND ep.key   = 'page_location'
    AND REGEXP_CONTAINS(
          ep.value.string_value,
          r'^https?://shop\.googlemerchandisestore\.com'
        )
)

SELECT
  page_path,
  COUNT(*) AS total_page_views
FROM dec_pageviews
GROUP BY page_path
ORDER BY total_page_views DESC
LIMIT 1 OFFSET 1;   -- 2nd‑highest