/*  Sessions by Default Channel – December 2020  */
WITH events_dec20 AS (
    /* union every December-2020 intraday table */
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
/* flatten the event-parameter array only for session_start rows */
session_params AS (
    SELECT
        e."USER_PSEUDO_ID",
        ep.value:"key"::STRING   AS param_key,
        ep.value:"value"         AS param_val
    FROM events_dec20 e,
         LATERAL FLATTEN ( INPUT => TRY_PARSE_JSON(e."EVENT_PARAMS") ) ep
    WHERE e."EVENT_NAME" = 'session_start'
),
/* pivot parameters into one row per session (using user-id + ga_session_id) */
sessions AS (
    SELECT
        "USER_PSEUDO_ID",
        MAX(CASE WHEN param_key = 'ga_session_id'
                 THEN COALESCE( param_val:"int_value"::STRING,
                                param_val:"string_value"::STRING ) END) AS session_id,
        MAX(CASE WHEN param_key = 'source'   THEN param_val:"string_value"::STRING END) AS source,
        MAX(CASE WHEN param_key = 'medium'   THEN param_val:"string_value"::STRING END) AS medium,
        MAX(CASE WHEN param_key = 'campaign' THEN param_val:"string_value"::STRING END) AS campaign
    FROM session_params
    GROUP BY "USER_PSEUDO_ID"
),
/* assign each session to a GA4 default channel */
channels AS (
    SELECT
        "USER_PSEUDO_ID",
        COALESCE(session_id,'0') AS session_id,
        CASE
            WHEN LOWER(source) = '(direct)'
                 AND LOWER(NVL(medium,'')) IN ('(not set)','(none)','')
                                                             THEN 'Direct'
            WHEN REGEXP_LIKE(LOWER(campaign),'cross-network')
                                                             THEN 'Cross-network'
            WHEN ( REGEXP_LIKE(LOWER(source),
                   '(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)')
                   OR REGEXP_LIKE(LOWER(campaign),'(^|[^a-df-z])shop|shopping') )
                 AND REGEXP_LIKE(LOWER(medium),'(cp|ppc|retargeting|paid)')
                                                             THEN 'Paid Shopping'
            WHEN  REGEXP_LIKE(LOWER(source),
                   '(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
                 AND REGEXP_LIKE(LOWER(medium),'(cp|ppc|paid)')
                                                             THEN 'Paid Search'
            WHEN  REGEXP_LIKE(LOWER(source),
                   '(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
                 AND REGEXP_LIKE(LOWER(medium),'(cp|ppc|retargeting|paid)')
                                                             THEN 'Paid Social'
            WHEN  REGEXP_LIKE(LOWER(source),
                   '(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
                 AND REGEXP_LIKE(LOWER(medium),'(cp|ppc|retargeting|paid)')
                                                             THEN 'Paid Video'
            WHEN LOWER(medium) IN ('display','banner','expandable','interstitial','cpm')
                                                             THEN 'Display'
            WHEN ( REGEXP_LIKE(LOWER(source),
                   '(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)')
                   OR REGEXP_LIKE(LOWER(campaign),'(^|[^a-df-z])shop|shopping') )
                                                             THEN 'Organic Shopping'
            WHEN ( REGEXP_LIKE(LOWER(source),
                   '(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
                   OR LOWER(medium) IN ('social','social-network','social-media','sm',
                                        'social network','social media') )
                                                             THEN 'Organic Social'
            WHEN ( REGEXP_LIKE(LOWER(source),
                   '(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
                   OR REGEXP_LIKE(LOWER(medium),'video') )
                                                             THEN 'Organic Video'
            WHEN  REGEXP_LIKE(LOWER(source),
                   '(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
                 OR LOWER(medium) = 'organic'                THEN 'Organic Search'
            WHEN LOWER(medium) = 'referral'                  THEN 'Referral'
            WHEN LOWER(source) IN ('email','e-mail','e_mail','e mail')
                 OR LOWER(medium) IN ('email','e-mail','e_mail','e mail')
                                                             THEN 'Email'
            WHEN LOWER(medium) = 'affiliate'                 THEN 'Affiliates'
            WHEN LOWER(medium) = 'audio'                     THEN 'Audio'
            WHEN LOWER(source) = 'sms' OR LOWER(medium) = 'sms'
                                                             THEN 'SMS'
            WHEN LOWER(medium) LIKE '%push'
                 OR LOWER(medium) LIKE '%mobile%'
                 OR LOWER(medium) LIKE '%notification%'       THEN 'Mobile Push Notifications'
            ELSE 'Unassigned'
        END AS channel
    FROM sessions
)
/* final result: distinct sessions per channel */
SELECT
    channel                                                     AS "CHANNEL",
    COUNT( DISTINCT "USER_PSEUDO_ID"||'-'||session_id )         AS "TOTAL_SESSIONS"
FROM channels
GROUP BY channel
ORDER BY "TOTAL_SESSIONS" DESC NULLS LAST;