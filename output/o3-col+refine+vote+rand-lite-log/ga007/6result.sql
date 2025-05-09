WITH total AS (
  SELECT COUNT(*) AS total_page_views
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),
pdp AS (
  SELECT COUNT(*) AS pdp_page_views
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`,
       UNNEST(event_params) AS ep
  WHERE event_name = 'page_view'
    AND ep.key = 'page_location'
    AND ep.value.string_value IS NOT NULL
    AND REGEXP_CONTAINS(
          LOWER(ep.value.string_value),
          r'/(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)/[^/]*\+'
        )
)
SELECT
  pdp.pdp_page_views,
  total.total_page_views,
  ROUND(100 * pdp.pdp_page_views / total.total_page_views, 4) AS pdp_percentage
FROM pdp, total;