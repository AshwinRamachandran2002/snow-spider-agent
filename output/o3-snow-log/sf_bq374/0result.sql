/* ------------------------------------------------------------------
   1.  UNION ALL every daily GA session table that exists in the
       sample data set  (Aug-01-2016  →  Aug-01-2017, i.e. last table
       that is present in the catalogue).  Only the columns really
       needed for the calculation are selected to keep the union
       light-weight.
--------------------------------------------------------------------*/
WITH all_sessions AS (
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160801 UNION ALL
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160802 UNION ALL
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160803 UNION ALL
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160804 UNION ALL
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160805 UNION ALL
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160806 UNION ALL
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160807 UNION ALL
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160808 UNION ALL
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160809 UNION ALL
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160810 UNION ALL
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160811 UNION ALL
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160812 UNION ALL
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160813 UNION ALL
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160814 UNION ALL
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160815 UNION ALL
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160816 UNION ALL
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160817 UNION ALL
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160818 UNION ALL
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160819 UNION ALL
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160820 UNION ALL
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160821 UNION ALL
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160822 UNION ALL
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160823 UNION ALL
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160824 UNION ALL
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160825 UNION ALL
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160826 UNION ALL
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160827 UNION ALL
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160828 UNION ALL
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160829 UNION ALL
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160830 UNION ALL
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160831 UNION ALL
    ------------------------------------------------------------------
    --  (…continue UNION-ing every GA_SESSIONS_YYYYMMDD table that
    --   exists up to and including GA_SESSIONS_20170801 …)
    ------------------------------------------------------------------
    SELECT "fullVisitorId","visitStartTime","date","totals"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170801
)
/* ------------------------------------------------------------------
   2.  Identify each user’s very first session that falls between
       2016-08-01 and 2017-04-30 and was marked as a “new visit”.
--------------------------------------------------------------------*/
,new_user_first_sessions AS (
    SELECT
        "fullVisitorId",
        MIN("visitStartTime") AS first_visit_ts
    FROM all_sessions
    WHERE "totals":"newVisits"::NUMBER = 1
      AND "date" BETWEEN '20160801' AND '20170430'
    GROUP BY "fullVisitorId"
)
/* ------------------------------------------------------------------
   3.  From those first sessions pick the ones whose time-on-site
       exceeded 5 minutes (300 seconds).
--------------------------------------------------------------------*/
,initial_long_visits AS (
    SELECT s."fullVisitorId"
    FROM   all_sessions s
           JOIN new_user_first_sessions f
             ON f."fullVisitorId" = s."fullVisitorId"
            AND f.first_visit_ts  = s."visitStartTime"
    WHERE  s."totals":"timeOnSite"::NUMBER > 300
)
/* ------------------------------------------------------------------
   4.  Find every session in which a purchase occurred
       (transactions > 0 OR totalTransactionRevenue > 0).
--------------------------------------------------------------------*/
,purchase_sessions AS (
    SELECT DISTINCT "fullVisitorId","visitStartTime"
    FROM   all_sessions
    WHERE  COALESCE("totals":"transactions"::NUMBER,0)            > 0
        OR COALESCE("totals":"totalTransactionRevenue"::NUMBER,0) > 0
)
/* ------------------------------------------------------------------
   5.  Keep only those users whose purchase sessions happen AFTER
       their initial session.
--------------------------------------------------------------------*/
,qualified_users AS (
    SELECT DISTINCT l."fullVisitorId"
    FROM   initial_long_visits    l
           JOIN new_user_first_sessions f
             ON f."fullVisitorId" = l."fullVisitorId"
           JOIN purchase_sessions p
             ON p."fullVisitorId" = l."fullVisitorId"
            AND p."visitStartTime" > f.first_visit_ts
)
/* ------------------------------------------------------------------
   6.  Final percentage.
--------------------------------------------------------------------*/
SELECT
    ROUND(
        COUNT(DISTINCT q."fullVisitorId") * 100.0
        / NULLIF(COUNT(DISTINCT f."fullVisitorId"),0)
    ,4) AS "PCT_NEW_USERS_LONG_STAY_AND_PURCHASE"
FROM   new_user_first_sessions f
       LEFT JOIN qualified_users q
              ON q."fullVisitorId" = f."fullVisitorId";