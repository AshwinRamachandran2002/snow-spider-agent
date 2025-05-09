/*  Total number of sessions per Default Channel Group – December 2020  */
WITH "DEC_EVENTS" AS (
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
/* keep only the session_start events (one row = one session) */
"SESSION_STARTS" AS (
    SELECT
        "EVENT_DATE",
        "USER_PSEUDO_ID",
        "EVENT_TIMESTAMP",
        "EVENT_PARAMS"
    FROM "DEC_EVENTS"
    WHERE "EVENT_NAME" = 'session_start'
),
/* pull out source / medium / campaign from the nested event_params record */
"SESSION_TRAFFIC" AS (
    SELECT
        ss."EVENT_DATE",
        ss."USER_PSEUDO_ID",
        ss."EVENT_TIMESTAMP",
        /* lower-casing simplifies later REGEXP/CASE logic */
        MAX(CASE WHEN ep.value:key::string = 'source'   THEN LOWER(ep.value:value:string_value::string)   END) AS "source",
        MAX(CASE WHEN ep.value:key::string = 'medium'   THEN LOWER(ep.value:value:string_value::string)   END) AS "medium",
        MAX(CASE WHEN ep.value:key::string = 'campaign' THEN LOWER(ep.value:value:string_value::string)   END) AS "campaign"
    FROM "SESSION_STARTS" ss,
         LATERAL FLATTEN(INPUT => ss."EVENT_PARAMS") ep
    GROUP BY
        ss."EVENT_DATE",
        ss."USER_PSEUDO_ID",
        ss."EVENT_TIMESTAMP"
),
/* map every session to a GA4 Default Channel Group */
"CHANNEL_GRP" AS (
    SELECT
        CASE
            WHEN "source" = '(direct)'
                 AND ( "medium" IS NULL OR "medium" IN ('(not set)','(none)') )                                                  THEN 'Direct'
            WHEN REGEXP_LIKE("campaign", 'cross[-_ ]*network', 'i')                                                             THEN 'Cross-network'
            /* --- Paid channels --- */
            WHEN REGEXP_LIKE("source",  '(alibaba|amazon|google ?shopping|shopify|etsy|ebay|stripe|walmart)', 'i')
                 AND REGEXP_LIKE("medium", '(cp|ppc|retargeting|paid)', 'i')                                                     THEN 'Paid Shopping'
            WHEN REGEXP_LIKE("campaign",'(^|[^a-df-z])shop(ping)?', 'i')
                 AND REGEXP_LIKE("medium", '(cp|ppc|retargeting|paid)', 'i')                                                     THEN 'Paid Shopping'
            WHEN REGEXP_LIKE("source",  '(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)', 'i')
                 AND REGEXP_LIKE("medium", '(cp|ppc|paid)', 'i')                                                                 THEN 'Paid Search'
            WHEN REGEXP_LIKE("source",  '(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)', 'i')
                 AND REGEXP_LIKE("medium", '(cp|ppc|retargeting|paid)', 'i')                                                     THEN 'Paid Social'
            WHEN REGEXP_LIKE("source",  '(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)', 'i')
                 AND REGEXP_LIKE("medium", '(cp|ppc|retargeting|paid)', 'i')                                                     THEN 'Paid Video'
            /* --- Display --- */
            WHEN "medium" IN ('display','banner','expandable','interstitial','cpm')                                              THEN 'Display'
            /* --- Organic channels --- */
            WHEN REGEXP_LIKE("source",  '(alibaba|amazon|google ?shopping|shopify|etsy|ebay|stripe|walmart)', 'i')
                 OR  REGEXP_LIKE("campaign",'(^|[^a-df-z])shop(ping)?', 'i')                                                     THEN 'Organic Shopping'
            WHEN REGEXP_LIKE("source",  '(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)', 'i')
                 OR  "medium" IN ('social','social-network','social-media','sm','social network','social media')                THEN 'Organic Social'
            WHEN REGEXP_LIKE("source",  '(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)', 'i')
                 OR  REGEXP_LIKE("medium", 'video', 'i')                                                                         THEN 'Organic Video'
            WHEN REGEXP_LIKE("source",  '(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)', 'i')
                 OR  "medium" = 'organic'                                                                                        THEN 'Organic Search'
            /* --- Other individual channels --- */
            WHEN "medium" = 'referral'                                                                                           THEN 'Referral'
            WHEN "source" IN ('email','e-mail','e_mail','e mail')
                 OR  "medium" IN ('email','e-mail','e_mail','e mail')                                                             THEN 'Email'
            WHEN "medium" = 'affiliate'                                                                                          THEN 'Affiliates'
            WHEN "medium" = 'audio'                                                                                              THEN 'Audio'
            WHEN "source" = 'sms' OR "medium" = 'sms'                                                                            THEN 'SMS'
            WHEN REGEXP_LIKE("medium", 'push$', 'i') OR REGEXP_LIKE("medium", '(mobile|notification)', 'i')                       THEN 'Mobile Push Notifications'
            ELSE 'Unassigned'
        END AS "channel"
    FROM "SESSION_TRAFFIC"
)
/* final tally */
SELECT
    "channel",
    COUNT(*) AS "total_sessions"
FROM "CHANNEL_GRP"
GROUP BY "channel"
ORDER BY "total_sessions" DESC NULLS LAST;