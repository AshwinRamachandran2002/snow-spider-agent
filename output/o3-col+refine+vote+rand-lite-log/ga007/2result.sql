WITH page_views AS (
  -- pull the URL for every 2021-01-02 page_view
  SELECT
    JSON_VALUE(TO_JSON_STRING(p.value), '$.string_value') AS page_url
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`,
       UNNEST(event_params) AS p
  WHERE event_name = 'page_view'
    AND p.key     = 'page_location'
)
SELECT
  ROUND(
    SAFE_DIVIDE(
      SUM(
        CASE
          WHEN                       -- PDP rules
               ARRAY_LENGTH(SPLIT(page_url, '/')) >= 6             -- ≥5 “/” → ≥6 segments
           AND REGEXP_CONTAINS(page_url, r'[^/]+\+[^/]+$')         -- “+” in last segment
           AND REGEXP_CONTAINS(LOWER(page_url),                    -- category keyword
               r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
        THEN 1
        ELSE 0
        END
      ),
      COUNT(1)
    ) * 100,
    4
  ) AS pdp_pageview_percentage
FROM page_views;