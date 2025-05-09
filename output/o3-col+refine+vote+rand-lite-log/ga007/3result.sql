-- Percentage of Product-Detail-Page (PDP) views among all page_view events on 2-Jan-2021  
SELECT
  ROUND(
    SAFE_DIVIDE(
      SUM(
        CASE
          WHEN ARRAY_LENGTH(SPLIT(ep.value.string_value, '/')) >= 5
               AND REGEXP_CONTAINS(
                     LOWER(ARRAY_REVERSE(SPLIT(ep.value.string_value, '/'))[OFFSET(0)]),
                     r'\+'                                  -- “+” in last URL segment
                   )
               AND REGEXP_CONTAINS(
                     LOWER(ep.value.string_value),           -- category present
                     r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)'
                   )
          THEN 1 ELSE 0
        END
      ),
      COUNT(*)                 -- total page_view events that contain page_location
    ) * 100,
    4                         -- keep four decimal places
  ) AS pdp_percentage
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`,
UNNEST(event_params) AS ep
WHERE event_name = 'page_view'
  AND ep.key   = 'page_location';