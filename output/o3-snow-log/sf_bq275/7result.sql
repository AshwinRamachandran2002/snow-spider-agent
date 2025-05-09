/*  Visitor-IDs whose very first transaction
    (i) happened after their first visit and
    (ii) was made on a device whose deviceCategory = 'mobile'
*/
WITH all_aug_2016 AS (   ------------------------------------------------ Step 1
    /* one explicit SELECT per day-table in August-2016                  */
    SELECT "fullVisitorId"                               AS full_visitor_id,
           TO_DATE("date",'YYYYMMDD')                    AS session_date,
           "totals"                                      AS totals_v,
           "device"                                      AS device_v
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160801
    UNION ALL SELECT "fullVisitorId",TO_DATE("date",'YYYYMMDD'),"totals","device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160802
    UNION ALL SELECT "fullVisitorId",TO_DATE("date",'YYYYMMDD'),"totals","device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160803
    UNION ALL SELECT "fullVisitorId",TO_DATE("date",'YYYYMMDD'),"totals","device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160804
    UNION ALL SELECT "fullVisitorId",TO_DATE("date",'YYYYMMDD'),"totals","device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160805
    UNION ALL SELECT "fullVisitorId",TO_DATE("date",'YYYYMMDD'),"totals","device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160806
    UNION ALL SELECT "fullVisitorId",TO_DATE("date",'YYYYMMDD'),"totals","device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160807
    UNION ALL SELECT "fullVisitorId",TO_DATE("date",'YYYYMMDD'),"totals","device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160808
    UNION ALL SELECT "fullVisitorId",TO_DATE("date",'YYYYMMDD'),"totals","device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160809
    UNION ALL SELECT "fullVisitorId",TO_DATE("date",'YYYYMMDD'),"totals","device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160810
    UNION ALL SELECT "fullVisitorId",TO_DATE("date",'YYYYMMDD'),"totals","device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160811
    UNION ALL SELECT "fullVisitorId",TO_DATE("date",'YYYYMMDD'),"totals","device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160812
    UNION ALL SELECT "fullVisitorId",TO_DATE("date",'YYYYMMDD'),"totals","device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160813
    UNION ALL SELECT "fullVisitorId",TO_DATE("date",'YYYYMMDD'),"totals","device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160814
    UNION ALL SELECT "fullVisitorId",TO_DATE("date",'YYYYMMDD'),"totals","device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160815
    UNION ALL SELECT "fullVisitorId",TO_DATE("date",'YYYYMMDD'),"totals","device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160816
    UNION ALL SELECT "fullVisitorId",TO_DATE("date",'YYYYMMDD'),"totals","device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160817
    UNION ALL SELECT "fullVisitorId",TO_DATE("date",'YYYYMMDD'),"totals","device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160818
    UNION ALL SELECT "fullVisitorId",TO_DATE("date",'YYYYMMDD'),"totals","device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160819
    UNION ALL SELECT "fullVisitorId",TO_DATE("date",'YYYYMMDD'),"totals","device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160820
    UNION ALL SELECT "fullVisitorId",TO_DATE("date",'YYYYMMDD'),"totals","device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160821
    UNION ALL SELECT "fullVisitorId",TO_DATE("date",'YYYYMMDD'),"totals","device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160822
    UNION ALL SELECT "fullVisitorId",TO_DATE("date",'YYYYMMDD'),"totals","device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160823
    UNION ALL SELECT "fullVisitorId",TO_DATE("date",'YYYYMMDD'),"totals","device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160824
    UNION ALL SELECT "fullVisitorId",TO_DATE("date",'YYYYMMDD'),"totals","device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160825
    UNION ALL SELECT "fullVisitorId",TO_DATE("date",'YYYYMMDD'),"totals","device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160826
    UNION ALL SELECT "fullVisitorId",TO_DATE("date",'YYYYMMDD'),"totals","device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160827
    UNION ALL SELECT "fullVisitorId",TO_DATE("date",'YYYYMMDD'),"totals","device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160828
    UNION ALL SELECT "fullVisitorId",TO_DATE("date",'YYYYMMDD'),"totals","device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160829
    UNION ALL SELECT "fullVisitorId",TO_DATE("date",'YYYYMMDD'),"totals","device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160830
    UNION ALL SELECT "fullVisitorId",TO_DATE("date",'YYYYMMDD'),"totals","device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160831
),
parsed AS (                  ------------------------------------------------ Step 2
    SELECT full_visitor_id,
           session_date,
           TRY_TO_NUMBER(totals_v:"transactions"::STRING)            AS transactions,
           TRY_TO_NUMBER(totals_v:"totalTransactionRevenue"::STRING) AS txn_revenue,
           device_v:"deviceCategory"::STRING                         AS device_category
    FROM   all_aug_2016
),
per_user AS (                ------------------------------------------------ Step 3
    SELECT  full_visitor_id,
            MIN(session_date)                                              AS first_visit_date,
            MIN(CASE WHEN COALESCE(transactions,0) > 0
                       OR COALESCE(txn_revenue,0) > 0
                     THEN session_date END)                                 AS first_txn_date
    FROM    parsed
    GROUP BY full_visitor_id
),
first_txn_device AS (        ------------------------------------------------ Step 4
    SELECT  p.full_visitor_id,
            p.device_category
    FROM    parsed p
    JOIN    per_user u
      ON    p.full_visitor_id = u.full_visitor_id
     AND    p.session_date    = u.first_txn_date
)
SELECT  DISTINCT             ------------------------------------------------ Step 5
        u.full_visitor_id AS visitor_id
FROM    per_user u
JOIN    first_txn_device d
  ON    u.full_visitor_id = d.full_visitor_id
WHERE   u.first_txn_date IS NOT NULL
  AND   u.first_txn_date > u.first_visit_date
  AND   d.device_category = 'mobile'
ORDER BY visitor_id;