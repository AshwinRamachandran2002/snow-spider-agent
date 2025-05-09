/*  Return visitor IDs whose first transaction happened
    (a) on a mobile device and
    (b) after their very first visit (only August-2016 data are used)  */
WITH all_sessions AS (
    SELECT  "fullVisitorId"                                AS visitor_id ,
            TO_DATE("date",'YYYYMMDD')                     AS session_date ,
            PARSE_JSON("totals")                           AS totals_json ,
            PARSE_JSON("device")                           AS device_json
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160801
 UNION ALL SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), PARSE_JSON("totals"), PARSE_JSON("device")
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160802
 UNION ALL SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), PARSE_JSON("totals"), PARSE_JSON("device")
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160803
 UNION ALL SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), PARSE_JSON("totals"), PARSE_JSON("device")
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160804
 UNION ALL SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), PARSE_JSON("totals"), PARSE_JSON("device")
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160805
 UNION ALL SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), PARSE_JSON("totals"), PARSE_JSON("device")
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160806
 UNION ALL SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), PARSE_JSON("totals"), PARSE_JSON("device")
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160807
 UNION ALL SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), PARSE_JSON("totals"), PARSE_JSON("device")
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160808
 UNION ALL SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), PARSE_JSON("totals"), PARSE_JSON("device")
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160809
 UNION ALL SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), PARSE_JSON("totals"), PARSE_JSON("device")
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160810
 UNION ALL SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), PARSE_JSON("totals"), PARSE_JSON("device")
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160811
 UNION ALL SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), PARSE_JSON("totals"), PARSE_JSON("device")
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160812
 UNION ALL SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), PARSE_JSON("totals"), PARSE_JSON("device")
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160813
 UNION ALL SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), PARSE_JSON("totals"), PARSE_JSON("device")
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160814
 UNION ALL SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), PARSE_JSON("totals"), PARSE_JSON("device")
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160815
 UNION ALL SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), PARSE_JSON("totals"), PARSE_JSON("device")
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160816
 UNION ALL SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), PARSE_JSON("totals"), PARSE_JSON("device")
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160817
 UNION ALL SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), PARSE_JSON("totals"), PARSE_JSON("device")
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160818
 UNION ALL SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), PARSE_JSON("totals"), PARSE_JSON("device")
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160819
 UNION ALL SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), PARSE_JSON("totals"), PARSE_JSON("device")
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160820
 UNION ALL SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), PARSE_JSON("totals"), PARSE_JSON("device")
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160821
 UNION ALL SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), PARSE_JSON("totals"), PARSE_JSON("device")
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160822
 UNION ALL SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), PARSE_JSON("totals"), PARSE_JSON("device")
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160823
 UNION ALL SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), PARSE_JSON("totals"), PARSE_JSON("device")
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160824
 UNION ALL SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), PARSE_JSON("totals"), PARSE_JSON("device")
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160825
 UNION ALL SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), PARSE_JSON("totals"), PARSE_JSON("device")
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160826
 UNION ALL SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), PARSE_JSON("totals"), PARSE_JSON("device")
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160827
 UNION ALL SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), PARSE_JSON("totals"), PARSE_JSON("device")
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160828
 UNION ALL SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), PARSE_JSON("totals"), PARSE_JSON("device")
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160829
 UNION ALL SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), PARSE_JSON("totals"), PARSE_JSON("device")
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160830
 UNION ALL SELECT "fullVisitorId", TO_DATE("date",'YYYYMMDD'), PARSE_JSON("totals"), PARSE_JSON("device")
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160831
),
/* first time each visitor appeared */
first_visit AS (
    SELECT visitor_id ,
           MIN(session_date) AS first_visit_date
    FROM   all_sessions
    GROUP  BY visitor_id
),
/* first session that contains a transaction */
first_transaction AS (
    SELECT visitor_id ,
           MIN(session_date) AS first_txn_date
    FROM   all_sessions
    WHERE  TRY_TO_NUMBER( (totals_json:"totalTransactionRevenue")::STRING ) > 0
    GROUP  BY visitor_id
),
/* of those first-transaction sessions, keep only the ones done on a mobile device */
first_txn_on_mobile AS (
    SELECT a.visitor_id
    FROM   all_sessions a
    JOIN   first_transaction t
           ON a.visitor_id = t.visitor_id
          AND a.session_date = t.first_txn_date
    WHERE  LOWER( a.device_json:"deviceCategory"::STRING ) = 'mobile'
)
/* final answer */
SELECT DISTINCT m.visitor_id
FROM   first_txn_on_mobile  m
JOIN   first_visit          v ON m.visitor_id = v.visitor_id
JOIN   first_transaction    t ON m.visitor_id = t.visitor_id
WHERE  t.first_txn_date > v.first_visit_date
ORDER  BY visitor_id;