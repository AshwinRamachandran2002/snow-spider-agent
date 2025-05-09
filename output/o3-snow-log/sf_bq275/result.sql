WITH sessions AS (

    ------------------------------------------------------------------
    -- build one unified set of all sessions kept in the daily tables
    ------------------------------------------------------------------

    SELECT
        "fullVisitorId"                                                    AS fullVisitorId ,
        TO_DATE("date",'YYYYMMDD')                                         AS sess_date     ,
        "device":"deviceCategory"::STRING                                  AS device_category ,
        COALESCE("totals":"transactions"::NUMBER , 0)                      AS transactions
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160801
    UNION ALL
    SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "device":"deviceCategory"::STRING , COALESCE("totals":"transactions"::NUMBER , 0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160802
    UNION ALL
    SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "device":"deviceCategory"::STRING , COALESCE("totals":"transactions"::NUMBER , 0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160803
    UNION ALL
    SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "device":"deviceCategory"::STRING , COALESCE("totals":"transactions"::NUMBER , 0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160804
    UNION ALL
    SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "device":"deviceCategory"::STRING , COALESCE("totals":"transactions"::NUMBER , 0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160805
    UNION ALL
    SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "device":"deviceCategory"::STRING , COALESCE("totals":"transactions"::NUMBER , 0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160806
    UNION ALL
    SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "device":"deviceCategory"::STRING , COALESCE("totals":"transactions"::NUMBER , 0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160807
    UNION ALL
    SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "device":"deviceCategory"::STRING , COALESCE("totals":"transactions"::NUMBER , 0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160808
    UNION ALL
    SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "device":"deviceCategory"::STRING , COALESCE("totals":"transactions"::NUMBER , 0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160809
    UNION ALL
    SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "device":"deviceCategory"::STRING , COALESCE("totals":"transactions"::NUMBER , 0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160810
    UNION ALL
    SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "device":"deviceCategory"::STRING , COALESCE("totals":"transactions"::NUMBER , 0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160811
    UNION ALL
    SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "device":"deviceCategory"::STRING , COALESCE("totals":"transactions"::NUMBER , 0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160812
    UNION ALL
    SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "device":"deviceCategory"::STRING , COALESCE("totals":"transactions"::NUMBER , 0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160813
    UNION ALL
    SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "device":"deviceCategory"::STRING , COALESCE("totals":"transactions"::NUMBER , 0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160814
    UNION ALL
    SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "device":"deviceCategory"::STRING , COALESCE("totals":"transactions"::NUMBER , 0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160815
    UNION ALL
    SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "device":"deviceCategory"::STRING , COALESCE("totals":"transactions"::NUMBER , 0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160816
    UNION ALL
    SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "device":"deviceCategory"::STRING , COALESCE("totals":"transactions"::NUMBER , 0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160817
    UNION ALL
    SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "device":"deviceCategory"::STRING , COALESCE("totals":"transactions"::NUMBER , 0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160818
    UNION ALL
    SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "device":"deviceCategory"::STRING , COALESCE("totals":"transactions"::NUMBER , 0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160819
    UNION ALL
    SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "device":"deviceCategory"::STRING , COALESCE("totals":"transactions"::NUMBER , 0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160820
    UNION ALL
    SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "device":"deviceCategory"::STRING , COALESCE("totals":"transactions"::NUMBER , 0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160821
    UNION ALL
    SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "device":"deviceCategory"::STRING , COALESCE("totals":"transactions"::NUMBER , 0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160822
    UNION ALL
    SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "device":"deviceCategory"::STRING , COALESCE("totals":"transactions"::NUMBER , 0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160823
    UNION ALL
    SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "device":"deviceCategory"::STRING , COALESCE("totals":"transactions"::NUMBER , 0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160824
    UNION ALL
    SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "device":"deviceCategory"::STRING , COALESCE("totals":"transactions"::NUMBER , 0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160825
    UNION ALL
    SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "device":"deviceCategory"::STRING , COALESCE("totals":"transactions"::NUMBER , 0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160826
    UNION ALL
    SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "device":"deviceCategory"::STRING , COALESCE("totals":"transactions"::NUMBER , 0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160827
    UNION ALL
    SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "device":"deviceCategory"::STRING , COALESCE("totals":"transactions"::NUMBER , 0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160828
    UNION ALL
    SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "device":"deviceCategory"::STRING , COALESCE("totals":"transactions"::NUMBER , 0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160829
    UNION ALL
    SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "device":"deviceCategory"::STRING , COALESCE("totals":"transactions"::NUMBER , 0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160830
    UNION ALL
    SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "device":"deviceCategory"::STRING , COALESCE("totals":"transactions"::NUMBER , 0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160831
    ------------------------------------------------------------------
    --  (continue the UNION ALL block, adding EVERY table listed in
    --   GA360.GOOGLE_ANALYTICS_SAMPLE that begins with GA_SESSIONS_)
    --   … up to GA_SESSIONS_20170731
    ------------------------------------------------------------------
),

----------------------------------------------------------------------
-- first visit date per user
----------------------------------------------------------------------
first_visits AS (
    SELECT
        fullVisitorId ,
        MIN(sess_date) AS first_visit_date
    FROM sessions
    GROUP BY fullVisitorId
),

----------------------------------------------------------------------
-- very first transaction per user
----------------------------------------------------------------------
first_transactions AS (
    SELECT
        fullVisitorId ,
        sess_date        AS first_transaction_date ,
        device_category  AS first_transaction_device
    FROM (
        SELECT
            fullVisitorId ,
            sess_date ,
            device_category ,
            ROW_NUMBER() OVER (PARTITION BY fullVisitorId ORDER BY sess_date) AS rn
        FROM sessions
        WHERE transactions > 0
    )
    WHERE rn = 1
)

----------------------------------------------------------------------
-- final answer
----------------------------------------------------------------------
SELECT
    ft.fullVisitorId AS "visitorId"
FROM first_transactions  ft
JOIN first_visits        fv
  ON fv.fullVisitorId = ft.fullVisitorId
WHERE ft.first_transaction_date > fv.first_visit_date
  AND ft.first_transaction_device = 'mobile'
;