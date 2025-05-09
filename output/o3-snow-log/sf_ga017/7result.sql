WITH page_views AS (
    /* ---------- 01 Jan 2021 ---------- */
    SELECT  "USER_PSEUDO_ID"                                     AS user_id ,
            ep.value:"value":"string_value"::string              AS page_location
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210101",
            LATERAL FLATTEN ( input => "EVENT_PARAMS" ) ep
    WHERE   "EVENT_NAME" = 'page_view'
      AND   ep.value:"key"::string = 'page_location'

    UNION ALL
    /* ---------- 02 Jan 2021 ---------- */
    SELECT  "USER_PSEUDO_ID",
            ep.value:"value":"string_value"::string
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102",
            LATERAL FLATTEN ( input => "EVENT_PARAMS" ) ep
    WHERE   "EVENT_NAME" = 'page_view'
      AND   ep.value:"key"::string = 'page_location'

    UNION ALL
    /* ---------- 03 Jan 2021 ---------- */
    SELECT  "USER_PSEUDO_ID",
            ep.value:"value":"string_value"::string
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210103",
            LATERAL FLATTEN ( input => "EVENT_PARAMS" ) ep
    WHERE   "EVENT_NAME" = 'page_view'
      AND   ep.value:"key"::string = 'page_location'

    UNION ALL
    /* ---------- 04 Jan 2021 ---------- */
    SELECT  "USER_PSEUDO_ID",
            ep.value:"value":"string_value"::string
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210104",
            LATERAL FLATTEN ( input => "EVENT_PARAMS" ) ep
    WHERE   "EVENT_NAME" = 'page_view'
      AND   ep.value:"key"::string = 'page_location'

    UNION ALL
    /* ---------- 05 Jan 2021 ---------- */
    SELECT  "USER_PSEUDO_ID",
            ep.value:"value":"string_value"::string
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210105",
            LATERAL FLATTEN ( input => "EVENT_PARAMS" ) ep
    WHERE   "EVENT_NAME" = 'page_view'
      AND   ep.value:"key"::string = 'page_location'

    UNION ALL
    /* ---------- 06 Jan 2021 ---------- */
    SELECT  "USER_PSEUDO_ID",
            ep.value:"value":"string_value"::string
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210106",
            LATERAL FLATTEN ( input => "EVENT_PARAMS" ) ep
    WHERE   "EVENT_NAME" = 'page_view'
      AND   ep.value:"key"::string = 'page_location'

    UNION ALL
    /* ---------- 07 Jan 2021 ---------- */
    SELECT  "USER_PSEUDO_ID",
            ep.value:"value":"string_value"::string
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210107",
            LATERAL FLATTEN ( input => "EVENT_PARAMS" ) ep
    WHERE   "EVENT_NAME" = 'page_view'
      AND   ep.value:"key"::string = 'page_location'

    UNION ALL
    /* ---------- 08 Jan 2021 ---------- */
    SELECT  "USER_PSEUDO_ID",
            ep.value:"value":"string_value"::string
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210108",
            LATERAL FLATTEN ( input => "EVENT_PARAMS" ) ep
    WHERE   "EVENT_NAME" = 'page_view'
      AND   ep.value:"key"::string = 'page_location'

    UNION ALL
    /* ---------- 09 Jan 2021 ---------- */
    SELECT  "USER_PSEUDO_ID",
            ep.value:"value":"string_value"::string
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210109",
            LATERAL FLATTEN ( input => "EVENT_PARAMS" ) ep
    WHERE   "EVENT_NAME" = 'page_view'
      AND   ep.value:"key"::string = 'page_location'

    UNION ALL
    /* ---------- 10 Jan 2021 ---------- */
    SELECT  "USER_PSEUDO_ID",
            ep.value:"value":"string_value"::string
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210110",
            LATERAL FLATTEN ( input => "EVENT_PARAMS" ) ep
    WHERE   "EVENT_NAME" = 'page_view'
      AND   ep.value:"key"::string = 'page_location'

    UNION ALL
    /* ---------- 11 Jan 2021 ---------- */
    SELECT  "USER_PSEUDO_ID",
            ep.value:"value":"string_value"::string
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210111",
            LATERAL FLATTEN ( input => "EVENT_PARAMS" ) ep
    WHERE   "EVENT_NAME" = 'page_view'
      AND   ep.value:"key"::string = 'page_location'
    
    UNION ALL
    /* ---------- 12 Jan 2021 ---------- */
    SELECT  "USER_PSEUDO_ID",
            ep.value:"value":"string_value"::string
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210112",
            LATERAL FLATTEN ( input => "EVENT_PARAMS" ) ep
    WHERE   "EVENT_NAME" = 'page_view'
      AND   ep.value:"key"::string = 'page_location'
    
    UNION ALL
    /* ---------- 13 Jan 2021 ---------- */
    SELECT  "USER_PSEUDO_ID",
            ep.value:"value":"string_value"::string
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210113",
            LATERAL FLATTEN ( input => "EVENT_PARAMS" ) ep
    WHERE   "EVENT_NAME" = 'page_view'
      AND   ep.value:"key"::string = 'page_location'
    
    UNION ALL
    /* ---------- 14 Jan 2021 ---------- */
    SELECT  "USER_PSEUDO_ID",
            ep.value:"value":"string_value"::string
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210114",
            LATERAL FLATTEN ( input => "EVENT_PARAMS" ) ep
    WHERE   "EVENT_NAME" = 'page_view'
      AND   ep.value:"key"::string = 'page_location'
    
    UNION ALL
    /* ---------- 15 Jan 2021 ---------- */
    SELECT  "USER_PSEUDO_ID",
            ep.value:"value":"string_value"::string
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210115",
            LATERAL FLATTEN ( input => "EVENT_PARAMS" ) ep
    WHERE   "EVENT_NAME" = 'page_view'
      AND   ep.value:"key"::string = 'page_location'
    
    UNION ALL
    /* ---------- 16 Jan 2021 ---------- */
    SELECT  "USER_PSEUDO_ID",
            ep.value:"value":"string_value"::string
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210116",
            LATERAL FLATTEN ( input => "EVENT_PARAMS" ) ep
    WHERE   "EVENT_NAME" = 'page_view'
      AND   ep.value:"key"::string = 'page_location'
    
    UNION ALL
    /* ---------- 17 Jan 2021 ---------- */
    SELECT  "USER_PSEUDO_ID",
            ep.value:"value":"string_value"::string
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210117",
            LATERAL FLATTEN ( input => "EVENT_PARAMS" ) ep
    WHERE   "EVENT_NAME" = 'page_view'
      AND   ep.value:"key"::string = 'page_location'
    
    UNION ALL
    /* ---------- 18 Jan 2021 ---------- */
    SELECT  "USER_PSEUDO_ID",
            ep.value:"value":"string_value"::string
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210118",
            LATERAL FLATTEN ( input => "EVENT_PARAMS" ) ep
    WHERE   "EVENT_NAME" = 'page_view'
      AND   ep.value:"key"::string = 'page_location'
    
    UNION ALL
    /* ---------- 19 Jan 2021 ---------- */
    SELECT  "USER_PSEUDO_ID",
            ep.value:"value":"string_value"::string
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210119",
            LATERAL FLATTEN ( input => "EVENT_PARAMS" ) ep
    WHERE   "EVENT_NAME" = 'page_view'
      AND   ep.value:"key"::string = 'page_location'
    
    UNION ALL
    /* ---------- 20 Jan 2021 ---------- */
    SELECT  "USER_PSEUDO_ID",
            ep.value:"value":"string_value"::string
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210120",
            LATERAL FLATTEN ( input => "EVENT_PARAMS" ) ep
    WHERE   "EVENT_NAME" = 'page_view'
      AND   ep.value:"key"::string = 'page_location'
    
    UNION ALL
    /* ---------- 21 Jan 2021 ---------- */
    SELECT  "USER_PSEUDO_ID",
            ep.value:"value":"string_value"::string
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210121",
            LATERAL FLATTEN ( input => "EVENT_PARAMS" ) ep
    WHERE   "EVENT_NAME" = 'page_view'
      AND   ep.value:"key"::string = 'page_location'
    
    UNION ALL
    /* ---------- 22 Jan 2021 ---------- */
    SELECT  "USER_PSEUDO_ID",
            ep.value:"value":"string_value"::string
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210122",
            LATERAL FLATTEN ( input => "EVENT_PARAMS" ) ep
    WHERE   "EVENT_NAME" = 'page_view'
      AND   ep.value:"key"::string = 'page_location'
    
    UNION ALL
    /* ---------- 23 Jan 2021 ---------- */
    SELECT  "USER_PSEUDO_ID",
            ep.value:"value":"string_value"::string
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210123",
            LATERAL FLATTEN ( input => "EVENT_PARAMS" ) ep
    WHERE   "EVENT_NAME" = 'page_view'
      AND   ep.value:"key"::string = 'page_location'

    UNION ALL
    /* ---------- 24 Jan 2021 ---------- */
    SELECT  "USER_PSEUDO_ID",
            ep.value:"value":"string_value"::string
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210124",
            LATERAL FLATTEN ( input => "EVENT_PARAMS" ) ep
    WHERE   "EVENT_NAME" = 'page_view'
      AND   ep.value:"key"::string = 'page_location'
    
    UNION ALL
    /* ---------- 25 Jan 2021 ---------- */
    SELECT  "USER_PSEUDO_ID",
            ep.value:"value":"string_value"::string
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210125",
            LATERAL FLATTEN ( input => "EVENT_PARAMS" ) ep
    WHERE   "EVENT_NAME" = 'page_view'
      AND   ep.value:"key"::string = 'page_location'

    UNION ALL
    /* ---------- 26 Jan 2021 ---------- */
    SELECT  "USER_PSEUDO_ID",
            ep.value:"value":"string_value"::string
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210126",
            LATERAL FLATTEN ( input => "EVENT_PARAMS" ) ep
    WHERE   "EVENT_NAME" = 'page_view'
      AND   ep.value:"key"::string = 'page_location'
    
    UNION ALL
    /* ---------- 27 Jan 2021 ---------- */
    SELECT  "USER_PSEUDO_ID",
            ep.value:"value":"string_value"::string
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210127",
            LATERAL FLATTEN ( input => "EVENT_PARAMS" ) ep
    WHERE   "EVENT_NAME" = 'page_view'
      AND   ep.value:"key"::string = 'page_location'
    
    UNION ALL
    /* ---------- 28 Jan 2021 ---------- */
    SELECT  "USER_PSEUDO_ID",
            ep.value:"value":"string_value"::string
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210128",
            LATERAL FLATTEN ( input => "EVENT_PARAMS" ) ep
    WHERE   "EVENT_NAME" = 'page_view'
      AND   ep.value:"key"::string = 'page_location'
    
    UNION ALL
    /* ---------- 29 Jan 2021 ---------- */
    SELECT  "USER_PSEUDO_ID",
            ep.value:"value":"string_value"::string
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210129",
            LATERAL FLATTEN ( input => "EVENT_PARAMS" ) ep
    WHERE   "EVENT_NAME" = 'page_view'
      AND   ep.value:"key"::string = 'page_location'

    UNION ALL
    /* ---------- 30 Jan 2021 ---------- */
    SELECT  "USER_PSEUDO_ID",
            ep.value:"value":"string_value"::string
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210130",
            LATERAL FLATTEN ( input => "EVENT_PARAMS" ) ep
    WHERE   "EVENT_NAME" = 'page_view'
      AND   ep.value:"key"::string = 'page_location'
    
    UNION ALL
    /* ---------- 31 Jan 2021 ---------- */
    SELECT  "USER_PSEUDO_ID",
            ep.value:"value":"string_value"::string
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210131",
            LATERAL FLATTEN ( input => "EVENT_PARAMS" ) ep
    WHERE   "EVENT_NAME" = 'page_view'
      AND   ep.value:"key"::string = 'page_location'
),

/* Count how many times each page_location was visited */
page_counts AS (
    SELECT  page_location,
            COUNT(*) AS visit_cnt
    FROM    page_views
    GROUP BY page_location
),

/* Get the single most-visited page_location */
top_page AS (
    SELECT  page_location
    FROM    page_counts
    ORDER BY visit_cnt DESC NULLS LAST
    LIMIT 1
)

/* Final answer: number of distinct users who viewed that top page */
SELECT  COUNT(DISTINCT user_id) AS distinct_users
FROM    page_views
JOIN    top_page USING (page_location);