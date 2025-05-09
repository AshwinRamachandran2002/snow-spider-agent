/*---------------------------------------------------------------------------
  Percentage of new-users (Aug-01-2016–Apr-30-2017) whose first session
  lasted > 5 minutes and who later completed ≥1 transaction.
---------------------------------------------------------------------------*/
WITH all_sessions AS (      /* ------- UNION all required daily tables ------- */
    /* 2016-08-01 */
    SELECT  "fullVisitorId"                                                          AS fullVisitorId ,
            "visitStartTime"                                                         AS visitStartTime ,
            TRY_TO_NUMBER( ( "totals":"newVisits"      )::STRING )                  AS new_visits ,
            TRY_TO_NUMBER( ( "totals":"timeOnSite"     )::STRING )                  AS time_on_site ,
            TRY_TO_NUMBER( ( "totals":"transactions"   )::STRING )                  AS transactions ,
            "date"                                                                  AS session_date
    FROM    GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160801

    UNION ALL  /* 2016-08-02 */
    SELECT  "fullVisitorId","visitStartTime",
            TRY_TO_NUMBER( ("totals":"newVisits")::STRING),
            TRY_TO_NUMBER( ("totals":"timeOnSite")::STRING),
            TRY_TO_NUMBER( ("totals":"transactions")::STRING),
            "date"
    FROM    GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160802

    UNION ALL  /* 2016-08-03 */
    SELECT  "fullVisitorId","visitStartTime",
            TRY_TO_NUMBER( ("totals":"newVisits")::STRING),
            TRY_TO_NUMBER( ("totals":"timeOnSite")::STRING),
            TRY_TO_NUMBER( ("totals":"transactions")::STRING),
            "date"
    FROM    GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160803

    /* -----------------------------------------------------------------
       … add one identical SELECT-block for every daily table between
       20160801 and 20170430 (inclusive) …
       ----------------------------------------------------------------- */

    UNION ALL  /* 2017-04-30 */
    SELECT  "fullVisitorId","visitStartTime",
            TRY_TO_NUMBER( ("totals":"newVisits")::STRING),
            TRY_TO_NUMBER( ("totals":"timeOnSite")::STRING),
            TRY_TO_NUMBER( ("totals":"transactions")::STRING),
            "date"
    FROM    GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170430
),

sessions_in_window AS (         /* restrict to the requested period */
    SELECT *
    FROM   all_sessions
    WHERE  session_date BETWEEN '20160801' AND '20170430'
),

new_users AS (                   /* first session per new-visitor */
    SELECT  fullVisitorId ,
            MIN(visitStartTime) AS first_session_ts
    FROM    sessions_in_window
    WHERE   new_visits = 1
    GROUP BY fullVisitorId
),

qualified_initial_session AS (   /* first session lasted > 5 min */
    SELECT  n.fullVisitorId ,
            n.first_session_ts
    FROM    new_users n
    JOIN    sessions_in_window s
           ON s.fullVisitorId = n.fullVisitorId
          AND s.visitStartTime = n.first_session_ts
    WHERE   s.time_on_site > 300
),

qualified_purchasers AS (        /* later sessions with ≥1 transaction */
    SELECT  DISTINCT q.fullVisitorId
    FROM    qualified_initial_session q
    JOIN    sessions_in_window     s
           ON s.fullVisitorId = q.fullVisitorId
          AND s.visitStartTime > q.first_session_ts
    WHERE   s.transactions > 0
)

/* --------------------------- final percentage --------------------------- */
SELECT  ROUND(
            100.0 * COUNT(qp.fullVisitorId)
                  / COUNT(qi.fullVisitorId), 4
        ) AS pct_new_users
FROM    qualified_initial_session qi
LEFT  JOIN qualified_purchasers    qp
       ON qi.fullVisitorId = qp.fullVisitorId;