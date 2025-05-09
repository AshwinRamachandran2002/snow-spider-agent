/* -----------------------------------------------
   Navigation flow for user 1362228.4966015575
   28-Jan-2021  –  page_view events only
------------------------------------------------ */
WITH raw_events AS (                     -- page_view hits for the day
    SELECT
        "EVENT_TIMESTAMP",
        TRY_PARSE_JSON("EVENT_PARAMS")   AS event_params
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210128"
    WHERE "USER_PSEUDO_ID" = '1362228.4966015575'
      AND "EVENT_NAME"     = 'page_view'
),

extracted AS (                           -- pull page_location / page_title
    SELECT
        r."EVENT_TIMESTAMP"                                                 AS event_ts ,
        MAX(CASE WHEN p.value:"key" = 'page_location'
                 THEN p.value:"value":"string_value" END)::STRING           AS page_location ,
        MAX(CASE WHEN p.value:"key" = 'page_title'
                 THEN p.value:"value":"string_value" END)::STRING           AS page_title
    FROM raw_events r ,
         LATERAL FLATTEN( INPUT => r.event_params ) p
    GROUP BY r."EVENT_TIMESTAMP"
),

classified AS (                          -- prepare path-segments for rules
    SELECT
        event_ts ,
        page_title ,
        page_location ,
        LOWER( REPLACE( SPLIT_PART(page_location,'/',4) , '+',' ' ) )       AS seg4 ,
        LOWER( REPLACE( SPLIT_PART(page_location,'/',5) , '+',' ' ) )       AS seg5
    FROM extracted
),

tagged AS (                              -- convert to PDP / PLP / title
    SELECT
        event_ts ,
        CASE
            /* ---------- PDP ---------- */
            WHEN POSITION('+', SPLIT_PART(page_location,'/',5)) > 0
                 AND ( seg4 IN ('accessories','apparel','brands','campus collection',
                                 'drinkware','electronics','google redesign','lifestyle',
                                 'nest','new 2015 logo','notebooks journals','office',
                                 'shop by brand','small goods','stationery','wearables')
                    OR seg5 IN ('accessories','apparel','brands','campus collection',
                                 'drinkware','electronics','google redesign','lifestyle',
                                 'nest','new 2015 logo','notebooks journals','office',
                                 'shop by brand','small goods','stationery','wearables') )
            THEN 'PDP'

            /* ---------- PLP ---------- */
            WHEN POSITION('+', SPLIT_PART(page_location,'/',4)) = 0
                 AND POSITION('+', SPLIT_PART(page_location,'/',5)) = 0
                 AND ( seg4 IN ('accessories','apparel','brands','campus collection',
                                 'drinkware','electronics','google redesign','lifestyle',
                                 'nest','new 2015 logo','notebooks journals','office',
                                 'shop by brand','small goods','stationery','wearables')
                    OR seg5 IN ('accessories','apparel','brands','campus collection',
                                 'drinkware','electronics','google redesign','lifestyle',
                                 'nest','new 2015 logo','notebooks journals','office',
                                 'shop by brand','small goods','stationery','wearables') )
            THEN 'PLP'

            /* --------- Other ---------- */
            ELSE page_title
        END AS step
    FROM classified
),

dedup AS (                               -- drop consecutive duplicates
    SELECT
        event_ts ,
        step ,
        LAG(step) OVER (ORDER BY event_ts) AS prev_step
    FROM tagged
),

sequence AS (                            -- first row of each run, give order #
    SELECT
        step ,
        ROW_NUMBER() OVER (ORDER BY event_ts) AS rn
    FROM dedup
    WHERE step IS NOT NULL
      AND ( prev_step IS NULL OR prev_step <> step )
)

SELECT
    LISTAGG(step , ' >> ') WITHIN GROUP (ORDER BY rn) AS navigation_flow
FROM sequence;