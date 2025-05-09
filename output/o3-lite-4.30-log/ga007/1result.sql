SELECT
  ROUND(
    SAFE_DIVIDE(
      COUNTIF(
        REGEXP_CONTAINS(
          LOWER(ep.value.string_value),
          r'/((accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables))/[^/]*\+[^/]*$'
        )
      ),
      COUNT(*)
    ) * 100,
    4
  ) AS percentage_pdp_page_views
FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`,
  UNNEST(event_params) AS ep
WHERE
  event_date = '20210102'
  AND event_name = 'page_view'
  AND ep.key = 'page_location';