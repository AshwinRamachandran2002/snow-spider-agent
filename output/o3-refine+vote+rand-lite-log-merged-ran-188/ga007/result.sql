-- percentage of Product‑Detail‑Page (PDP) page‑views on 2‑Jan‑2021
WITH pageviews AS (
  -- pull every page_view event for 2021‑01‑02 and grab its URL
  SELECT
    ep.value.string_value            AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`  ev
  JOIN UNNEST(ev.event_params) ep
  ON  ep.key = 'page_location'
  WHERE ev.event_name = 'page_view'
        AND ep.value.string_value IS NOT NULL
),
classified AS (
  SELECT
    page_location,
    SPLIT(page_location,'/')                       AS segments
  FROM pageviews
),
final AS (
  /* PDP definition:
       • ≥5 segments in the full URL string split by “/”
       • segment #4 or #5 (0‑based 3 / 4) is one of the recognised categories
       • last segment contains “+”
  */
  SELECT
    page_location,
    CASE
      WHEN ARRAY_LENGTH(segments) >= 5
           AND (
                REGEXP_CONTAINS(
                   UPPER(segments[SAFE_OFFSET(3)]), 
                   r'(ACCESSORIES|APPAREL|BRANDS|CAMPUS\+COLLECTION|DRINKWARE|ELECTRONICS|GOOGLE\+REDESIGN|LIFESTYLE|NEST|NEW\+2015\+LOGO|NOTEBOOKS\+JOURNALS|OFFICE|SHOP\+BY\+BRAND|SMALL\+GOODS|STATIONERY|WEARABLES)'
               )
               OR REGEXP_CONTAINS(
                   UPPER(segments[SAFE_OFFSET(4)]), 
                   r'(ACCESSORIES|APPAREL|BRANDS|CAMPUS\+COLLECTION|DRINKWARE|ELECTRONICS|GOOGLE\+REDESIGN|LIFESTYLE|NEST|NEW\+2015\+LOGO|NOTEBOOKS\+JOURNALS|OFFICE|SHOP\+BY\+BRAND|SMALL\+GOODS|STATIONERY|WEARABLES)'
               )
           )
           AND REGEXP_CONTAINS(
                 segments[ORDINAL(ARRAY_LENGTH(segments))],
                 r'\+'
               )
      THEN TRUE
      ELSE FALSE
    END                                            AS is_pdp
  FROM classified
)
SELECT
  ROUND(100 * SUM(CASE WHEN is_pdp THEN 1 ELSE 0 END) / COUNT(*), 4)
    AS percent_pdp_pageviews
FROM final;