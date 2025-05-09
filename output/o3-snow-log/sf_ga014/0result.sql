/*  GA-4  |  Sessions per Default Channel Group  |  December-2020  */

WITH unioned_events AS (      /* 1️⃣  stitch every daily export for Dec-2020 */
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201201"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201202"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201203"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201204"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201205"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201206"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201207"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201208"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201209"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201210"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201211"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201212"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201213"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201214"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201215"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201216"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201217"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201218"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201219"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201220"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201221"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201222"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201223"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201224"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201225"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201226"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201227"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201228"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201229"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201230"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201231"
),

sessions AS (                /* 2️⃣  isolate “session_start” & pull source / medium / campaign */
    SELECT
        u."EVENT_TIMESTAMP"                                              AS session_id,    -- 1-row-per-session
        LOWER( COALESCE( MAX( CASE WHEN ep.key_name = 'source'   THEN ep.str_val END ), '<other>' ) ) AS source,
        LOWER( COALESCE( MAX( CASE WHEN ep.key_name = 'medium'   THEN ep.str_val END ), '<other>' ) ) AS medium,
        LOWER( COALESCE( MAX( CASE WHEN ep.key_name = 'campaign' THEN ep.str_val END ), ''        ) ) AS campaign
    FROM unioned_events u
         ,LATERAL FLATTEN( INPUT => u."EVENT_PARAMS" ) f
         ,LATERAL (
              SELECT
                  f.value:"key"::STRING                                              AS key_name,
                  f.value:"value":"string_value"::STRING                             AS str_val
         ) ep
    WHERE u."EVENT_NAME" = 'session_start'
    GROUP BY session_id
),

channel_mapped AS (          /* 3️⃣  map to Google default channel-grouping */
    SELECT
        CASE
            WHEN source = '(direct)' AND medium IN ('(not set)', '(none)')                                                THEN 'Direct'
            WHEN campaign LIKE '%cross-network%'                                                                          THEN 'Cross-network'

            WHEN ( REGEXP_LIKE(source,'^(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)$')
                   OR REGEXP_LIKE(campaign,'(^|[^a-df-z])(shop|shopping)') )
                 AND REGEXP_LIKE(medium,'(cp|ppc|retargeting|paid)')                                                       THEN 'Paid Shopping'

            WHEN REGEXP_LIKE(source,'^(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)$')
                 AND REGEXP_LIKE(medium,'(cp|ppc|paid)')                                                                  THEN 'Paid Search'

            WHEN REGEXP_LIKE(source,'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
                 AND REGEXP_LIKE(medium,'(cp|ppc|retargeting|paid)')                                                       THEN 'Paid Social'

            WHEN REGEXP_LIKE(source,'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
                 AND REGEXP_LIKE(medium,'(cp|ppc|retargeting|paid)')                                                       THEN 'Paid Video'

            WHEN medium IN ('display','banner','expandable','interstitial','cpm')                                         THEN 'Display'

            WHEN ( REGEXP_LIKE(source,'^(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)$')
                   OR REGEXP_LIKE(campaign,'(^|[^a-df-z])(shop|shopping)') )                                              THEN 'Organic Shopping'

            WHEN ( REGEXP_LIKE(source,'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
                   OR medium IN ('social','social-network','social-media','sm','social network','social media') )          THEN 'Organic Social'

            WHEN ( REGEXP_LIKE(source,'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
                   OR REGEXP_LIKE(medium,'video') )                                                                       THEN 'Organic Video'

            WHEN ( REGEXP_LIKE(source,'^(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)$')
                   OR medium = 'organic')                                                                                 THEN 'Organic Search'

            WHEN medium = 'referral'                                                                                      THEN 'Referral'
            WHEN source IN ('email','e-mail','e_mail','e mail')
              OR medium IN ('email','e-mail','e_mail','e mail')                                                           THEN 'Email'
            WHEN medium = 'affiliate'                                                                                     THEN 'Affiliates'
            WHEN medium = 'audio'                                                                                         THEN 'Audio'
            WHEN source = 'sms' OR medium = 'sms'                                                                         THEN 'SMS'
            WHEN REGEXP_LIKE(medium,'push$') OR REGEXP_LIKE(medium,'(mobile|notification)')                                THEN 'Mobile Push Notifications'
            ELSE 'Unassigned'
        END AS channel
    FROM sessions
)

SELECT                      /* 4️⃣  final tally */
    channel,
    COUNT(*) AS total_sessions
FROM channel_mapped
GROUP BY channel
ORDER BY total_sessions DESC NULLS LAST;