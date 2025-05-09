/*  Sessions by Traffic Channel – December 2020  */
WITH all_dec_events AS (

    /* -----------------------------------------------------------------
       union every daily GA4 export table belonging to December 2020
    ----------------------------------------------------------------- */
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201201" UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201202" UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201203" UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201204" UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201205" UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201206" UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201207" UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201208" UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201209" UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201210" UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201211" UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201212" UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201213" UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201214" UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201215" UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201216" UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201217" UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201218" UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201219" UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201220" UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201221" UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201222" UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201223" UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201224" UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201225" UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201226" UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201227" UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201228" UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201229" UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201230" UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201231"

),

/* ---------------------------------------------------------------------
   keep only the “session_start” events and pull out source / medium / 
   campaign values from the event_params array 
------------------------------------------------------------------------ */
sessions AS (
    SELECT
        ae."EVENT_TIMESTAMP",                -- unique per event
        MAX(CASE WHEN ep.value:key = 'source'   THEN COALESCE(ep.value:value:string_value,
                                                              ep.value:value:int_value::STRING) END) AS source,
        MAX(CASE WHEN ep.value:key = 'medium'   THEN COALESCE(ep.value:value:string_value,
                                                              ep.value:value:int_value::STRING) END) AS medium,
        MAX(CASE WHEN ep.value:key = 'campaign' THEN COALESCE(ep.value:value:string_value,
                                                              ep.value:value:int_value::STRING) END) AS campaign
    FROM all_dec_events      ae
         ,LATERAL FLATTEN(input => ae."EVENT_PARAMS") ep
    WHERE ae."EVENT_NAME" = 'session_start'
    GROUP BY ae."EVENT_TIMESTAMP"
),

/* ---------------------------------------------------------------------
   derive Google-analytics style default channel grouping
------------------------------------------------------------------------ */
classified AS (
    SELECT
        CASE
            WHEN LOWER(source) = '(direct)'                AND LOWER(medium) IN ('(not set)', '(none)')
                 THEN 'Direct'

            WHEN campaign ILIKE '%cross-network%'          THEN 'Cross-network'

            WHEN (REGEXP_LIKE(LOWER(source)  , 'alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart')
                   OR REGEXP_LIKE(LOWER(campaign), '(^|[^a-df-z])shop|shopping'))
                 AND REGEXP_LIKE(LOWER(medium) , 'cp|ppc|retargeting|paid')
                 THEN 'Paid Shopping'

            WHEN REGEXP_LIKE(LOWER(source) , 'baidu|bing|duckduckgo|ecosia|google|yahoo|yandex')
                 AND REGEXP_LIKE(LOWER(medium), 'cp|ppc|paid')
                 THEN 'Paid Search'

            WHEN REGEXP_LIKE(LOWER(source) , 'badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp')
                 AND REGEXP_LIKE(LOWER(medium), 'cp|ppc|retargeting|paid')
                 THEN 'Paid Social'

            WHEN REGEXP_LIKE(LOWER(source) , 'dailymotion|disneyplus|netflix|youtube|vimeo|twitch')
                 AND REGEXP_LIKE(LOWER(medium), 'cp|ppc|retargeting|paid')
                 THEN 'Paid Video'

            WHEN LOWER(medium) IN ('display','banner','expandable','interstitial','cpm')
                 THEN 'Display'

            WHEN (REGEXP_LIKE(LOWER(source)  , 'alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart')
                   OR REGEXP_LIKE(LOWER(campaign), '(^|[^a-df-z])shop|shopping'))
                 THEN 'Organic Shopping'

            WHEN (REGEXP_LIKE(LOWER(source) , 'badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp')
                  OR LOWER(medium) IN ('social','social-network','social-media','sm','social network','social media'))
                 THEN 'Organic Social'

            WHEN (REGEXP_LIKE(LOWER(source) , 'dailymotion|disneyplus|netflix|youtube|vimeo|twitch')
                  OR REGEXP_LIKE(LOWER(medium) , 'video'))
                 THEN 'Organic Video'

            WHEN (REGEXP_LIKE(LOWER(source) , 'baidu|bing|duckduckgo|ecosia|google|yahoo|yandex')
                  OR LOWER(medium) = 'organic')
                 THEN 'Organic Search'

            WHEN LOWER(medium) = 'referral'                THEN 'Referral'
            WHEN LOWER(medium) = 'affiliate'               THEN 'Affiliates'
            WHEN LOWER(medium) = 'audio'                   THEN 'Audio'
            WHEN LOWER(source) IN ('email','e-mail','e_mail','e mail')
              OR LOWER(medium) IN ('email','e-mail','e_mail','e mail')
                 THEN 'Email'
            WHEN LOWER(source) = 'sms'  OR LOWER(medium) = 'sms'
                 THEN 'SMS'
            WHEN RIGHT(LOWER(medium),4) = 'push'
              OR REGEXP_LIKE(LOWER(medium), 'mobile|notification')
                 THEN 'Mobile Push Notifications'
            ELSE 'Unassigned'
        END                                                    AS channel
    FROM sessions
)

/* ---------------------------------------------------------------------
   final result
------------------------------------------------------------------------ */
SELECT
    channel,
    COUNT(*) AS sessions
FROM classified
GROUP BY channel
ORDER BY sessions DESC NULLS LAST;