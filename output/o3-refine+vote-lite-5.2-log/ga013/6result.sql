/* Pages visited by user 1402138.5184246691 on 2021‑01‑02
   – return page names, replacing names with PDP / PLP when rules apply */
WITH events AS (                        -- 1. grab title & URL per event
  SELECT
      e.event_timestamp,
      MAX(IF(p.key = 'page_title'   , p.value.string_value, NULL)) AS page_title,
      MAX(IF(p.key = 'page_location', p.value.string_value, NULL)) AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102` AS e
  CROSS JOIN UNNEST(e.event_params) AS p
  WHERE e.user_pseudo_id = '1402138.5184246691'
        AND p.key IN ('page_title','page_location')
  GROUP BY e.event_timestamp
),
split_url AS (                          -- 2. split URL into path segments
  SELECT
      *,
      SPLIT(REGEXP_REPLACE(page_location, r'^https?://', ''), '/') AS seg
  FROM events
),
prep AS (                               -- 3. pre‑compute helpers (len, seg4, seg5)
  SELECT
      *,
      ARRAY_LENGTH(seg)                     AS seg_len,
      LOWER(seg[OFFSET(3)])                 AS seg4,
      LOWER(seg[OFFSET(4)])                 AS seg5
  FROM split_url
),
classified AS (                          -- 4. label PDP / PLP where applicable
  SELECT
      *,
      CASE
        /* PDP: ≥5 segments, category in seg4/seg5, '+' in last segment              */
        WHEN seg_len >= 5
             AND (
                   seg4 IN ('accessories','apparel','brands','campus+collection','drinkware',
                             'electronics','google+redesign','lifestyle','nest','new+2015+logo',
                             'notebooks+journals','office','shop+by+brand','small+goods',
                             'stationery','wearables')
                OR seg5 IN ('accessories','apparel','brands','campus+collection','drinkware',
                             'electronics','google+redesign','lifestyle','nest','new+2015+logo',
                             'notebooks+journals','office','shop+by+brand','small+goods',
                             'stationery','wearables')
                 )
             AND REGEXP_CONTAINS(seg[OFFSET(seg_len-1)], r'\+')
        THEN 'PDP'
        /* PLP: ≥5 segments, category present, no '+' in seg4 or seg5                */
        WHEN seg_len >= 5
             AND (
                   seg4 IN ('accessories','apparel','brands','campus+collection','drinkware',
                             'electronics','google+redesign','lifestyle','nest','new+2015+logo',
                             'notebooks+journals','office','shop+by+brand','small+goods',
                             'stationery','wearables')
                OR seg5 IN ('accessories','apparel','brands','campus+collection','drinkware',
                             'electronics','google+redesign','lifestyle','nest','new+2015+logo',
                             'notebooks+journals','office','shop+by+brand','small+goods',
                             'stationery','wearables')
                 )
             AND NOT REGEXP_CONTAINS(seg4, r'\+')
             AND NOT REGEXP_CONTAINS(seg5, r'\+')
        THEN 'PLP'
      END AS page_type
  FROM prep
)
SELECT DISTINCT
       COALESCE(page_type, page_title) AS page_name
FROM   classified
ORDER  BY page_name;