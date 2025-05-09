WITH events AS (
    -- Pull every page_view for the user on 28-Jan-2021
    SELECT
        e."EVENT_TIMESTAMP",
        MAX(CASE WHEN ep.value:"key"::string = 'page_location'
                 THEN ep.value:"value":"string_value"::string END)  AS page_location,
        MAX(CASE WHEN ep.value:"key"::string = 'page_title'
                 THEN ep.value:"value":"string_value"::string END)  AS page_title
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210128"  AS e
         ,LATERAL FLATTEN(input => e."EVENT_PARAMS")            AS ep
    WHERE e."EVENT_NAME"    = 'page_view'
      AND e."USER_PSEUDO_ID" = '1362228.4966015575'
      AND e."EVENT_DATE"     = '20210128'
    GROUP BY e."EVENT_TIMESTAMP"
),

classified AS (
    /* Tag every row as PDP, PLP, or keep the original title */
    SELECT
        "EVENT_TIMESTAMP",
        COALESCE(page_title, '(not set)')                         AS raw_title,
        page_location,
        CASE
            /* PDP: last URL segment contains '+' and 4th or 5th segment is a recognised category */
            WHEN page_location IS NOT NULL
                 AND REGEXP_LIKE(page_location, '/[^/]*\\+[^/]*$')
                 AND REGEXP_LIKE(
                       LOWER(REPLACE(SPLIT_PART(page_location,'/',4),'+',' ')) ||
                       LOWER(REPLACE(SPLIT_PART(page_location,'/',5),'+',' ')),
                       '(accessories|apparel|brands|campus collection|drinkware|electronics|google redesign|lifestyle|nest|new 2015 logo|notebooks journals|office|shop by brand|small goods|stationery|wearables)'
                 )
            THEN 'PDP'

            /* PLP: no '+' in 4th/5th segment, but 4th or 5th segment is a recognised category */
            WHEN page_location IS NOT NULL
                 AND NOT REGEXP_LIKE(SPLIT_PART(page_location,'/',4),'\\+')
                 AND NOT REGEXP_LIKE(SPLIT_PART(page_location,'/',5),'\\+')
                 AND REGEXP_LIKE(
                       LOWER(REPLACE(SPLIT_PART(page_location,'/',4),'+',' ')) ||
                       LOWER(REPLACE(SPLIT_PART(page_location,'/',5),'+',' ')),
                       '(accessories|apparel|brands|campus collection|drinkware|electronics|google redesign|lifestyle|nest|new 2015 logo|notebooks journals|office|shop by brand|small goods|stationery|wearables)'
                 )
            THEN 'PLP'

            /* Otherwise keep the original page title */
            ELSE COALESCE(page_title, '(not set)')
        END                                                       AS page_label
    FROM events
),

-- remove immediately repeating labels
dedup AS (
    SELECT
        "EVENT_TIMESTAMP",
        page_label,
        LAG(page_label) OVER (ORDER BY "EVENT_TIMESTAMP") AS prev_label
    FROM classified
)

SELECT
    LISTAGG(page_label, ' >> ') WITHIN GROUP (ORDER BY "EVENT_TIMESTAMP") AS navigation_flow
FROM dedup
WHERE prev_label IS NULL OR prev_label <> page_label;