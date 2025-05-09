-- PDP share among all page views on 2021‑01‑02
WITH page_views AS (
  -- pull every page_view and its URL
  SELECT
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_location'
      LIMIT 1)                                            AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),
classified AS (
  SELECT
    page_location,
    SPLIT(page_location, '/')                            AS segs
  FROM page_views
),
flagged AS (
  SELECT
    CASE
      WHEN page_location IS NULL                       THEN FALSE
      WHEN ARRAY_LENGTH(segs) < 5                      THEN FALSE         -- need ≥5 segments
      WHEN NOT REGEXP_CONTAINS(                         -- last segment must contain “+”
             segs[SAFE_OFFSET(ARRAY_LENGTH(segs)-1)],
             r'\+')
                                                     THEN FALSE
      WHEN (                                            -- 4th or 5th segment must contain category word
            REGEXP_CONTAINS(
              LOWER(segs[SAFE_OFFSET(3)]),
              r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
        OR  REGEXP_CONTAINS(
              LOWER(segs[SAFE_OFFSET(4)]),
              r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
           )
                                                     THEN TRUE
      ELSE                                                FALSE
    END                                                   AS is_pdp
  FROM classified
)
SELECT
  ROUND(
        100 * SAFE_DIVIDE(SUM(CASE WHEN is_pdp THEN 1 ELSE 0 END),
                          COUNT(*))
       ,4)                                                AS pdp_page_view_percentage
FROM flagged;