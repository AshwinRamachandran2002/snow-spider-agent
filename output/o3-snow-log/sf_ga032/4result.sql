/* Navigation flow for USER_PSEUDO_ID = '1362228.4966015575' on 2021-01-28 (page_view events only) */
WITH events_filtered AS (           -- 1. keep only the needed rows and explode EVENT_PARAMS
    SELECT
        e."EVENT_TIMESTAMP"                                            AS ts,
        ep.value:key::string                                            AS param_key,
        ep.value:value:string_value::string                             AS string_val
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210128"  e,
         LATERAL FLATTEN (INPUT => e."EVENT_PARAMS")            ep
    WHERE e."EVENT_NAME"      = 'page_view'
      AND e."EVENT_DATE"      = '20210128'
      AND e."USER_PSEUDO_ID"  = '1362228.4966015575'
),  

pivoted AS (                       -- 2. pivot the parameters into columns
    SELECT
        ts,
        MAX(CASE WHEN param_key = 'page_location' THEN string_val END) AS page_location,
        MAX(CASE WHEN param_key = 'page_title'    THEN string_val END) AS page_title
    FROM events_filtered
    GROUP BY ts
),  

parsed AS (                        -- 3. derive path, segments, etc.
    SELECT
        ts,
        page_location,
        page_title,
        REGEXP_REPLACE(page_location, '^https?://[^/]+', '')                           AS path,
        SPLIT_PART(REGEXP_REPLACE(page_location, '^https?://[^/]+', ''), '/', -1)      AS last_segment
    FROM pivoted
),  

classified AS (                    -- 4. translate to PLP / PDP when rules match
    SELECT
        ts,
        CASE
            /* PDP: recognised category & '+' in last segment */
            WHEN REGEXP_LIKE(LOWER(path),
                 '/(accessories|apparel|brands|campus\\+collection|drinkware|electronics|google\\+redesign|lifestyle|nest|new\\+2015\\+logo|notebooks\\+journals|office|shop\\+by\\+brand|small\\+goods|stationery|wearables)/')
                 AND last_segment LIKE '%+%'                            THEN 'PDP'

            /* PLP: recognised category & no '+' in 4th or 5th segments */
            WHEN REGEXP_LIKE(LOWER(path),
                 '/(accessories|apparel|brands|campus\\+collection|drinkware|electronics|google\\+redesign|lifestyle|nest|new\\+2015\\+logo|notebooks\\+journals|office|shop\\+by\\+brand|small\\+goods|stationery|wearables)/')
                 AND SPLIT_PART(path,'/',4) NOT LIKE '%+%'
                 AND SPLIT_PART(path,'/',5) NOT LIKE '%+%'              THEN 'PLP'

            /* otherwise keep original title */
            ELSE page_title
        END AS page_label
    FROM parsed
),  

dedup AS (                         -- 5. remove consecutive duplicates
    SELECT
        ts,
        page_label
    FROM (
        SELECT
            ts,
            page_label,
            LAG(page_label) OVER (ORDER BY ts) AS prev_label
        FROM classified
    )
    WHERE prev_label IS NULL OR page_label <> prev_label
)  

/* 6. stitch the journey together */
SELECT
    LISTAGG(page_label, '>>') WITHIN GROUP (ORDER BY ts) AS navigation_flow
FROM dedup;