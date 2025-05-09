WITH all_events AS (

    /* -----------------------------------------------------------------
       Union every GA4 daily table for 2020-11-01 … 2020-11-30
       ----------------------------------------------------------------- */
    SELECT * FROM (
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201101" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201102" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201103" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201104" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201105" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201106" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201107" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201108" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201109" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201110" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201111" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201112" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201113" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201114" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201115" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201116" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201117" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201118" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201119" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201120" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201121" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201122" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201123" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201124" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201125" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201126" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201127" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201128" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201129" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201130"
    )

), purchases AS (

    /* -----------------------------------------------------------------
       Keep only purchase events that contain a GA session id and
       a non-null purchase_revenue_in_usd in the ecommerce record
       ----------------------------------------------------------------- */
    SELECT
        ae."USER_PSEUDO_ID",
        /* pull session id from the flattened event_params array */
        TO_NUMBER( ep.value:"value":"int_value")                AS ga_session_id,
        TO_DOUBLE( ae."ECOMMERCE":"purchase_revenue_in_usd")    AS purchase_revenue
    FROM all_events  ae,
         LATERAL FLATTEN(input => ae."EVENT_PARAMS") ep
    WHERE ae."EVENT_NAME" = 'purchase'
      AND ep.value:"key"           = 'ga_session_id'
      AND ae."ECOMMERCE":"purchase_revenue_in_usd" IS NOT NULL

), session_revenue AS (

    /* -----------------------------------------------------------------
       Aggregate to one revenue figure per session
       ----------------------------------------------------------------- */
    SELECT
        "USER_PSEUDO_ID",
        ga_session_id,
        SUM(purchase_revenue) AS session_revenue
    FROM purchases
    GROUP BY
        "USER_PSEUDO_ID",
        ga_session_id

), user_stats AS (

    /* -----------------------------------------------------------------
       Compute average revenue per purchase session per user;
       keep users with >1 purchase session
       ----------------------------------------------------------------- */
    SELECT
        "USER_PSEUDO_ID",
        AVG(session_revenue) AS avg_purchase_revenue_per_session
    FROM session_revenue
    GROUP BY "USER_PSEUDO_ID"
    HAVING COUNT(*) > 1

)

SELECT
    "USER_PSEUDO_ID",
    avg_purchase_revenue_per_session
FROM user_stats
ORDER BY
    avg_purchase_revenue_per_session DESC NULLS LAST;