WITH dec_events AS (   -- collect every GA4 export table for December-2020
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
session_starts AS (   -- keep only “session_start” events, pull traffic source fields
    SELECT
        LOWER(COALESCE("TRAFFIC_SOURCE":"source"::string , ''))      AS source ,
        LOWER(COALESCE("TRAFFIC_SOURCE":"medium"::string , ''))      AS medium ,
        LOWER(COALESCE("TRAFFIC_SOURCE":"name"::string   , ''))      AS campaign
    FROM dec_events
    WHERE "EVENT_NAME" = 'session_start'
),
classified AS (       -- apply GA-like channel-grouping rules
    SELECT
        CASE
            /* Direct */
            WHEN source = '(direct)' AND medium IN ('(not set)', '(none)', '')                THEN 'Direct'
            /* Paid Search */
            WHEN REGEXP_LIKE(source , '(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
                 AND REGEXP_LIKE(medium , '.*(cp|ppc|paid).*')                                THEN 'Paid Search'
            /* Organic Search */
            WHEN REGEXP_LIKE(source , '(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
                 AND medium = 'organic'                                                      THEN 'Organic Search'
            /* Paid Social */
            WHEN REGEXP_LIKE(source , '(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
                 AND REGEXP_LIKE(medium , '.*(cp|ppc|retargeting|paid).*')                    THEN 'Paid Social'
            /* Organic Social */
            WHEN REGEXP_LIKE(source , '(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
                 OR medium IN ('social','social-network','social-media','sm','social network','social media')
                                                                                                THEN 'Organic Social'
            /* Display */
            WHEN medium IN ('display','banner','expandable','interstitial','cpm')             THEN 'Display'
            /* Email */
            WHEN source IN ('email','e-mail','e_mail','e mail')
                 OR medium IN ('email','e-mail','e_mail','e mail')                            THEN 'Email'
            /* Referral */
            WHEN medium = 'referral'                                                         THEN 'Referral'
            /* Everything else */
            ELSE 'Unassigned'
        END AS channel_group
    FROM session_starts
),
summary AS (          -- count sessions per channel
    SELECT channel_group ,
           COUNT(*) AS sessions
    FROM   classified
    GROUP  BY channel_group
)
SELECT channel_group ,
       sessions
FROM (
      SELECT channel_group ,
             sessions ,
             ROW_NUMBER() OVER (ORDER BY sessions DESC NULLS LAST) AS channel_rank
      FROM   summary
) ranked
WHERE channel_rank = 4;