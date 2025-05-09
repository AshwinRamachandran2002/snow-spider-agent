WITH pageviews AS (
  SELECT
    SPLIT(
      (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
       WHERE ep.key = 'page_location'),
      '/'
    ) AS parts
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_date = '20210102'
    AND event_name = 'page_view'
),
classified AS (
  SELECT
    CASE
      WHEN ARRAY_LENGTH(parts) >= 5
           AND (
                 REGEXP_CONTAINS(LOWER(parts[3]),
                   r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
              OR REGEXP_CONTAINS(LOWER(parts[4]),
                   r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
               )
           AND parts[OFFSET(ARRAY_LENGTH(parts) - 1)] LIKE '%+%'
        THEN 'PDP'
        ELSE 'OTHER'
    END AS page_type
  FROM pageviews
)
SELECT
  ROUND(100 * COUNTIF(page_type = 'PDP') / COUNT(*), 4) AS percentage_pdp_page_views
FROM classified;