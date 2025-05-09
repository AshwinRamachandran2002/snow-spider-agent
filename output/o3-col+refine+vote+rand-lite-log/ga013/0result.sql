/* All unique pages (title or PDP / PLP) visited by the user on 2-Jan-2021 */
WITH pages AS (
  SELECT
    -- pull the page-title and page-location sitting inside event_params
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_title'
      LIMIT 1)                                                   AS page_title,

    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_location'
      LIMIT 1)                                                   AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE user_pseudo_id = '1402138.5184246691'
),
classified AS (
  SELECT
    page_title,
    CASE
      /* PDP rule */
      WHEN ARRAY_LENGTH(SPLIT(page_location,'/')) >= 5
           AND (
                 REGEXP_CONTAINS(LOWER(SPLIT(page_location,'/')[OFFSET(3)]),
                     r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)') OR
                 REGEXP_CONTAINS(LOWER(SPLIT(page_location,'/')[OFFSET(4)]),
                     r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
               )
           AND REGEXP_CONTAINS(
                 SPLIT(page_location,'/')[OFFSET(ARRAY_LENGTH(SPLIT(page_location,'/'))-1)],
                 r'\+')
           THEN 'PDP'

      /* PLP rule */
      WHEN ARRAY_LENGTH(SPLIT(page_location,'/')) >= 5
           AND (
                 REGEXP_CONTAINS(LOWER(SPLIT(page_location,'/')[OFFSET(3)]),
                     r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)') OR
                 REGEXP_CONTAINS(LOWER(SPLIT(page_location,'/')[OFFSET(4)]),
                     r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
               )
           AND NOT REGEXP_CONTAINS(
                 SPLIT(page_location,'/')[OFFSET(ARRAY_LENGTH(SPLIT(page_location,'/'))-1)],
                 r'\+')
           THEN 'PLP'
    END                                                          AS page_type
  FROM pages
)
SELECT DISTINCT
  COALESCE(page_type, page_title) AS page_name
FROM classified
ORDER BY page_name;