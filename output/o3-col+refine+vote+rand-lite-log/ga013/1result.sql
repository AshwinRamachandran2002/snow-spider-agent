/*  Pages visited by user 1402138.5184246691 on 2-Jan-2021
    – classified as PDP / PLP (or OTHER) according to the refined rules  */

WITH page_views AS (      -- 1. isolate page_title & page_location for the user/date
  SELECT
    ep_title.value.string_value AS page_title ,
    ep_loc.value.string_value   AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`  e
  CROSS JOIN UNNEST(e.event_params) ep_title
  CROSS JOIN UNNEST(e.event_params) ep_loc
  WHERE e.user_pseudo_id = '1402138.5184246691'
    AND ep_title.key = 'page_title'
    AND ep_loc.key   = 'page_location'
),

segments AS (             -- 2. split the URL into individual path segments
  SELECT
    page_title ,
    page_location ,
    SPLIT(page_location , '/') AS seg
  FROM page_views
),

classified AS (           -- 3. apply the refined PDP / PLP logic
  SELECT
    page_title ,
    CASE
      /* ---------- PDP ---------- */
      WHEN ARRAY_LENGTH(seg) >= 5
           AND (
                LOWER(seg[OFFSET(4)]) IN UNNEST([
                  'accessories','apparel','brands','campus+collection',
                  'drinkware','electronics','google+redesign','lifestyle',
                  'nest','new+2015+logo','notebooks+journals','office',
                  'shop+by+brand','small+goods','stationery','wearables'])
             OR (ARRAY_LENGTH(seg) >= 6 AND LOWER(seg[OFFSET(5)]) IN UNNEST([
                  'accessories','apparel','brands','campus+collection',
                  'drinkware','electronics','google+redesign','lifestyle',
                  'nest','new+2015+logo','notebooks+journals','office',
                  'shop+by+brand','small+goods','stationery','wearables']))
               )
           AND REGEXP_CONTAINS(seg[OFFSET(ARRAY_LENGTH(seg)-1)] , r'\+')
        THEN 'PDP'

      /* ---------- PLP ---------- */
      WHEN ARRAY_LENGTH(seg) >= 5
           AND (
                LOWER(seg[OFFSET(4)]) IN UNNEST([
                  'accessories','apparel','brands','campus+collection',
                  'drinkware','electronics','google+redesign','lifestyle',
                  'nest','new+2015+logo','notebooks+journals','office',
                  'shop+by+brand','small+goods','stationery','wearables'])
             OR (ARRAY_LENGTH(seg) >= 6 AND LOWER(seg[OFFSET(5)]) IN UNNEST([
                  'accessories','apparel','brands','campus+collection',
                  'drinkware','electronics','google+redesign','lifestyle',
                  'nest','new+2015+logo','notebooks+journals','office',
                  'shop+by+brand','small+goods','stationery','wearables']))
               )
           AND NOT REGEXP_CONTAINS(seg[OFFSET(4)] , r'\+')
           AND (ARRAY_LENGTH(seg) < 6 OR NOT REGEXP_CONTAINS(seg[OFFSET(5)] , r'\+'))
        THEN 'PLP'

      /* ---------- everything else ---------- */
      ELSE 'OTHER'
    END AS page_type
  FROM segments
)

SELECT DISTINCT
       page_title ,
       page_type
FROM   classified
ORDER  BY page_title;