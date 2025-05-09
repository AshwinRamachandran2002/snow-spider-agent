/* -----------------------------------------------------------
   Navigation flow (page_view only) for user 1362228.4966015575
   on 28-Jan-2021
------------------------------------------------------------ */
WITH events AS (   --------------------------------------------------
  /* Pull one row per GA event timestamp with its page_location & page_title */
  SELECT
      e."EVENT_TIMESTAMP"                                             AS event_ts ,
      MAX( CASE WHEN ep.value:key::string = 'page_location'
                THEN ep.value:value:string_value END )                AS page_location ,
      MAX( CASE WHEN ep.value:key::string = 'page_title'
                THEN ep.value:value:string_value  END )               AS page_title
  FROM  GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210128"  e,
        LATERAL FLATTEN ( INPUT => e."EVENT_PARAMS" )                 ep
  WHERE e."EVENT_NAME"     = 'page_view'
    AND e."USER_PSEUDO_ID" = '1362228.4966015575'
    AND e."EVENT_DATE"     = '20210128'
  GROUP BY e."EVENT_TIMESTAMP"
),
prep AS (           --------------------------------------------------
  /* Split the path into segments we can inspect */
  SELECT
      event_ts ,
      page_location ,
      page_title ,
      SPLIT( REGEXP_REPLACE( page_location , '^https?://[^/]+' , '' ) , '/' ) AS segments
  FROM events
),
classified AS (     --------------------------------------------------
  /* Decide whether the hit is a PDP, PLP or leave the original title   */
  SELECT
      event_ts ,
      CASE
          WHEN page_location IS NULL THEN page_title
          /* ---- Check for at least 5 path segments and category match ---- */
          WHEN ARRAY_SIZE(segments) >= 5
               AND REGEXP_LIKE(
                     REPLACE( UPPER( segments[3]::string ) ,' ','') || ',' ||
                     REPLACE( UPPER( segments[4]::string ) ,' ',''),
                     '(ACCESSORIES|APPAREL|BRANDS|CAMPUSCOLLECTION|DRINKWARE|ELECTRONICS|GOOGLEREDESIGN|LIFESTYLE|NEST|NEW2015LOGO|NOTEBOOKSJOURNALS|OFFICE|SHOPBYBRAND|SMALLGOODS|STATIONERY|WEARABLES)'
                 )
          THEN CASE
                   WHEN POSITION( '+' , segments[ ARRAY_SIZE(segments)-1 ]::string ) > 0
                   THEN 'PDP'
                   ELSE 'PLP'
               END
          ELSE page_title
      END                                                              AS label
  FROM prep
),
dedup AS (          --------------------------------------------------
  /* Remove consecutive duplicates (adjacent refreshes of same page)  */
  SELECT
      event_ts ,
      label ,
      LAG(label) OVER (ORDER BY event_ts) AS prev_label
  FROM classified
),
filtered AS (       --------------------------------------------------
  SELECT event_ts , label
  FROM   dedup
  WHERE  label IS NOT NULL
    AND ( prev_label IS NULL OR label <> prev_label )
)
SELECT
    LISTAGG( label , ' >> ' ) WITHIN GROUP ( ORDER BY event_ts )      AS navigation_flow
FROM filtered;