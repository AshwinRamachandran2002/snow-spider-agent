WITH page_events AS (   /* pull every page_view done by the user that day */
    SELECT
        e."EVENT_TIMESTAMP"                                               AS event_ts ,
        MAX( CASE WHEN f.value:"key"::string = 'page_title'
                  THEN f.value:"value":"string_value"::string END )       AS page_title ,
        MAX( CASE WHEN f.value:"key"::string = 'page_location'
                  THEN f.value:"value":"string_value"::string END )       AS page_url
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210128" e ,
         LATERAL FLATTEN( INPUT => e."EVENT_PARAMS" ) f
    WHERE e."EVENT_NAME"     = 'page_view'
      AND e."USER_PSEUDO_ID" = '1362228.4966015575'
      AND e."EVENT_DATE"     = '20210128'
    GROUP BY e."EVENT_TIMESTAMP"
),

classified AS (   /* break the URL into parts we need for PLP/PDP decision */
    SELECT
        event_ts,
        ARRAY_SIZE( SPLIT( page_url , '/' ) )                           AS segment_cnt,
        SPLIT_PART( page_url , '/' , 4 )                                AS segment4,
        SPLIT_PART( page_url , '/' , 5 )                                AS segment5,
        REGEXP_REPLACE( page_url , '.*/' , '' )                         AS last_segment,
        page_title,
        page_url
    FROM page_events
),

with_labels AS (  /* label each event as PDP / PLP / original title */
    SELECT
        event_ts,
        CASE
            WHEN (
                    UPPER( REPLACE( segment4 , '+' , ' ' ) ) IN (
                         'ACCESSORIES','APPAREL','BRANDS','CAMPUS COLLECTION','DRINKWARE','ELECTRONICS',
                         'GOOGLE REDESIGN','LIFESTYLE','NEST','NEW 2015 LOGO','NOTEBOOKS JOURNALS',
                         'OFFICE','SHOP BY BRAND','SMALL GOODS','STATIONERY','WEARABLES'
                    )
                 OR UPPER( REPLACE( segment5 , '+' , ' ' ) ) IN (
                         'ACCESSORIES','APPAREL','BRANDS','CAMPUS COLLECTION','DRINKWARE','ELECTRONICS',
                         'GOOGLE REDESIGN','LIFESTYLE','NEST','NEW 2015 LOGO','NOTEBOOKS JOURNALS',
                         'OFFICE','SHOP BY BRAND','SMALL GOODS','STATIONERY','WEARABLES'
                    )
                 )
              AND segment_cnt >= 5
              AND POSITION( '+' , last_segment ) > 0
            THEN 'PDP'

            WHEN (
                    UPPER( REPLACE( segment4 , '+' , ' ' ) ) IN (
                         'ACCESSORIES','APPAREL','BRANDS','CAMPUS COLLECTION','DRINKWARE','ELECTRONICS',
                         'GOOGLE REDESIGN','LIFESTYLE','NEST','NEW 2015 LOGO','NOTEBOOKS JOURNALS',
                         'OFFICE','SHOP BY BRAND','SMALL GOODS','STATIONERY','WEARABLES'
                    )
                 OR UPPER( REPLACE( segment5 , '+' , ' ' ) ) IN (
                         'ACCESSORIES','APPAREL','BRANDS','CAMPUS COLLECTION','DRINKWARE','ELECTRONICS',
                         'GOOGLE REDESIGN','LIFESTYLE','NEST','NEW 2015 LOGO','NOTEBOOKS JOURNALS',
                         'OFFICE','SHOP BY BRAND','SMALL GOODS','STATIONERY','WEARABLES'
                    )
                 )
              AND segment_cnt >= 5
              AND POSITION( '+' , segment4 ) = 0
              AND POSITION( '+' , segment5 ) = 0
            THEN 'PLP'

            ELSE COALESCE( page_title , 'UNKNOWN' )
        END AS page_label
    FROM classified
),

dedup AS (  /* drop consecutive duplicates */
    SELECT
        event_ts,
        page_label,
        CASE WHEN page_label = LAG( page_label ) OVER ( ORDER BY event_ts )
             THEN 0 ELSE 1 END AS is_new
    FROM with_labels
),

pruned AS (
    SELECT event_ts, page_label
    FROM   dedup
    WHERE  is_new = 1 OR is_new IS NULL
)

SELECT
    LISTAGG( page_label , '>>' ) WITHIN GROUP ( ORDER BY event_ts ) AS navigation_flow
FROM pruned;