WITH user_pageviews AS (   -- 1. keep only the wanted events for the wanted user/day
    SELECT
        e."EVENT_TIMESTAMP",
        MAX( CASE WHEN f.value:key::string = 'page_location'
                  THEN f.value:value:string_value::string
             END )                                    AS page_location ,
        MAX( CASE WHEN f.value:key::string = 'page_title'
                  THEN f.value:value:string_value::string
             END )                                    AS page_title
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210128"  e
         ,LATERAL FLATTEN( INPUT => PARSE_JSON(e."EVENT_PARAMS") ) f
    WHERE e."EVENT_NAME"     = 'page_view'
      AND e."USER_PSEUDO_ID" = '1362228.4966015575'
      AND e."EVENT_DATE"     = '20210128'
    GROUP BY e."EVENT_TIMESTAMP"
),

classified AS (          -- 2. decide whether the url is PDP / PLP or something else
    SELECT
        "EVENT_TIMESTAMP",
        page_location,
        page_title,
        SPLIT(page_location,'/')                                           AS segs
    FROM user_pageviews
),

labeled AS (
    SELECT
        "EVENT_TIMESTAMP",
        CASE
            /* ---------- PDP ---------- */
            WHEN page_location IS NOT NULL
                 AND ARRAY_SIZE(segs) >= 5
                 AND (
                        LOWER(REPLACE(segs[3]::string,'+',' ')) RLIKE '(accessories|apparel|brands|campus collection|drinkware|electronics|google redesign|lifestyle|nest|new 2015 logo|notebooks journals|office|shop by brand|small goods|stationery|wearables)'
                     OR LOWER(REPLACE(segs[4]::string,'+',' ')) RLIKE '(accessories|apparel|brands|campus collection|drinkware|electronics|google redesign|lifestyle|nest|new 2015 logo|notebooks journals|office|shop by brand|small goods|stationery|wearables)'
                 )
                 AND POSITION('+', segs[ARRAY_SIZE(segs)-1]::string) > 0
            THEN 'PDP'

            /* ---------- PLP ---------- */
            WHEN page_location IS NOT NULL
                 AND ARRAY_SIZE(segs) >= 5
                 AND (
                        LOWER(REPLACE(segs[3]::string,'+',' ')) RLIKE '(accessories|apparel|brands|campus collection|drinkware|electronics|google redesign|lifestyle|nest|new 2015 logo|notebooks journals|office|shop by brand|small goods|stationery|wearables)'
                     OR LOWER(REPLACE(segs[4]::string,'+',' ')) RLIKE '(accessories|apparel|brands|campus collection|drinkware|electronics|google redesign|lifestyle|nest|new 2015 logo|notebooks journals|office|shop by brand|small goods|stationery|wearables)'
                 )
                 AND POSITION('+', segs[3]::string) = 0
                 AND POSITION('+', segs[4]::string) = 0
            THEN 'PLP'

            /* ---------- anything else keeps its page title ---------- */
            ELSE COALESCE(page_title,'Unknown')
        END                                                        AS step_label
    FROM classified
),

ordered AS (             -- 3. chronological order & remove adjacent duplicates
    SELECT
        step_label,
        "EVENT_TIMESTAMP",
        ROW_NUMBER() OVER (ORDER BY "EVENT_TIMESTAMP")                           AS rn,
        LAG(step_label)  OVER (ORDER BY "EVENT_TIMESTAMP")                       AS prev_label
    FROM labeled
),
dedup AS (
    SELECT step_label, "EVENT_TIMESTAMP"
    FROM   ordered
    WHERE  prev_label IS NULL OR prev_label <> step_label
)

-- 4. build the final flow string
SELECT
    LISTAGG(step_label, ' >> ') WITHIN GROUP (ORDER BY "EVENT_TIMESTAMP") AS navigation_flow
FROM dedup;