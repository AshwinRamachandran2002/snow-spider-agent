WITH params AS (
    /* -----------------------------------------------
       1.  Pull all page_view events for the requested
           user and date and unnest EVENT_PARAMS
       ------------------------------------------------ */
    SELECT
        e."EVENT_TIMESTAMP",
        f.value:"key"::string          AS param_key,
        f.value:"value"                AS param_value
    FROM "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20210128"  e,
         LATERAL FLATTEN(input => e."EVENT_PARAMS")                 f
    WHERE e."USER_PSEUDO_ID" = '1362228.4966015575'
      AND e."EVENT_NAME"     = 'page_view'
),
page_level AS (
    /* -----------------------------------------------
       2.  Collapse the flattened parameters so each
           event-timestamp has one row with its URL
           and Title
       ------------------------------------------------ */
    SELECT
        "EVENT_TIMESTAMP",
        MAX(CASE WHEN param_key = 'page_location'
                 THEN param_value:"string_value"::string END) AS page_url,
        MAX(CASE WHEN param_key = 'page_title'
                 THEN param_value:"string_value"::string END) AS page_title
    FROM params
    GROUP BY "EVENT_TIMESTAMP"
),
classified AS (
    /* -----------------------------------------------
       3.  Classify each page as PDP / PLP using the
           refined rules.  If neither rule matches,
           keep the original title.
       ------------------------------------------------ */
    SELECT
        "EVENT_TIMESTAMP",
        page_title,
        page_url,
        CASE
            /* ---------- PDP ---------- */
            WHEN page_url IS NOT NULL
                 AND ARRAY_SIZE(SPLIT(page_url,'/')) >= 5
                 AND (
                       LOWER(SPLIT_PART(page_url,'/',4)) IN
                           ('accessories','apparel','brands','campus collection',
                            'drinkware','electronics','google redesign','lifestyle',
                            'nest','new 2015 logo','notebooks journals','office',
                            'shop by brand','small goods','stationery','wearables')
                       OR
                       LOWER(SPLIT_PART(page_url,'/',5)) IN
                           ('accessories','apparel','brands','campus collection',
                            'drinkware','electronics','google redesign','lifestyle',
                            'nest','new 2015 logo','notebooks journals','office',
                            'shop by brand','small goods','stationery','wearables')
                     )
                 AND POSITION('+', SPLIT_PART(page_url,'/',-1)) > 0
            THEN 'PDP'

            /* ---------- PLP ---------- */
            WHEN page_url IS NOT NULL
                 AND ARRAY_SIZE(SPLIT(page_url,'/')) >= 5
                 AND (
                       LOWER(SPLIT_PART(page_url,'/',4)) IN
                           ('accessories','apparel','brands','campus collection',
                            'drinkware','electronics','google redesign','lifestyle',
                            'nest','new 2015 logo','notebooks journals','office',
                            'shop by brand','small goods','stationery','wearables')
                       OR
                       LOWER(SPLIT_PART(page_url,'/',5)) IN
                           ('accessories','apparel','brands','campus collection',
                            'drinkware','electronics','google redesign','lifestyle',
                            'nest','new 2015 logo','notebooks journals','office',
                            'shop by brand','small goods','stationery','wearables')
                     )
                 AND POSITION('+', SPLIT_PART(page_url,'/',4)) = 0
                 AND POSITION('+', SPLIT_PART(page_url,'/',5)) = 0
            THEN 'PLP'

            /* ---------- All other pages ---------- */
            ELSE page_title
        END AS page_label
    FROM page_level
),
ordered AS (
    /* -----------------------------------------------
       4.  Order chronologically and mark row numbers
       ------------------------------------------------ */
    SELECT
        page_label,
        ROW_NUMBER() OVER (ORDER BY "EVENT_TIMESTAMP") AS rn
    FROM classified
),
dedup AS (
    /* -----------------------------------------------
       5.  Remove consecutive duplicates
       ------------------------------------------------ */
    SELECT
        page_label,
        rn
    FROM ordered
    QUALIFY page_label <> LAG(page_label) OVER (ORDER BY rn)
            OR LAG(page_label) OVER (ORDER BY rn) IS NULL
)
SELECT
    /* -----------------------------------------------
       6.  Build the navigation flow string
       ------------------------------------------------ */
    LISTAGG(page_label, ' >> ') WITHIN GROUP (ORDER BY rn) AS navigation_flow
FROM dedup;