WITH base AS (
  SELECT DISTINCT
         loc.value.string_value AS page_location,
         ttl.value.string_value AS page_title
  FROM   `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102` AS t
         CROSS JOIN UNNEST(t.event_params) AS loc
         CROSS JOIN UNNEST(t.event_params) AS ttl
  WHERE  t.event_date     = '20210102'
    AND  t.user_pseudo_id = '1402138.5184246691'
    AND  loc.key = 'page_location'
    AND  ttl.key = 'page_title'
),
classified AS (
  SELECT
    CASE
      WHEN ARRAY_LENGTH(SPLIT(page_location,'/')) >= 5
           AND REGEXP_CONTAINS(
                 LOWER(CONCAT(
                   IFNULL(SPLIT(page_location,'/')[SAFE_OFFSET(4)],''),'/',
                   IFNULL(SPLIT(page_location,'/')[SAFE_OFFSET(5)],'')
                 )),
                 r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)'
           )
           AND REGEXP_CONTAINS(
                 SPLIT(page_location,'/')[SAFE_OFFSET(ARRAY_LENGTH(SPLIT(page_location,'/'))-1)],
                 r'\+'
           )
      THEN 'PDP'
      WHEN ARRAY_LENGTH(SPLIT(page_location,'/')) >= 5
           AND REGEXP_CONTAINS(
                 LOWER(CONCAT(
                   IFNULL(SPLIT(page_location,'/')[SAFE_OFFSET(4)],''),'/',
                   IFNULL(SPLIT(page_location,'/')[SAFE_OFFSET(5)],'')
                 )),
                 r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)'
           )
           AND NOT REGEXP_CONTAINS(
                 SPLIT(page_location,'/')[SAFE_OFFSET(ARRAY_LENGTH(SPLIT(page_location,'/'))-1)],
                 r'\+'
           )
      THEN 'PLP'
      ELSE IFNULL(page_title,'Unknown')
    END AS page_name
  FROM base
)
SELECT DISTINCT
       page_name
FROM   classified
ORDER  BY page_name;