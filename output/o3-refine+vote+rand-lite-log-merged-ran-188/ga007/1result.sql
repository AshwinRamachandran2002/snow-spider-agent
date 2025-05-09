WITH page_views AS (
  -- pull every page_view together with its URL
  SELECT
    ep.value.string_value AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`,
       UNNEST(event_params) AS ep
  WHERE event_name = 'page_view'
    AND ep.key          = 'page_location'          -- the URL
    AND ep.value.string_value IS NOT NULL
),

classified AS (
  -- decide whether each URL is a PDP or not
  SELECT
    page_location,
    CASE
      WHEN                                                     -- at least five “/”‑segments
           ARRAY_LENGTH(SPLIT(page_location,'/')) >= 5
       AND                                                    -- last segment contains “+”
           REGEXP_CONTAINS(
             SPLIT(page_location,'/')[ORDINAL(ARRAY_LENGTH(SPLIT(page_location,'/')))],
             r'\+'
           )
       AND                                                    -- segment 4 or 5 matches a category name
          (
            REGEXP_CONTAINS(
               LOWER(SPLIT(page_location,'/')[OFFSET(3)]),
               r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)'
            )
            OR
            REGEXP_CONTAINS(
               LOWER(SPLIT(page_location,'/')[SAFE_OFFSET(4)]),
               r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)'
            )
          )
      THEN 'PDP'
      ELSE 'OTHER'
    END AS page_type
  FROM page_views
)

SELECT
  ROUND(
    SAFE_DIVIDE(
      SUM(CASE WHEN page_type = 'PDP' THEN 1 ELSE 0 END),
      COUNT(*)
    ) * 100,
  4) AS pdp_page_view_percentage
FROM classified;