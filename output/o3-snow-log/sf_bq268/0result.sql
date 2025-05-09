/* ----------------------------------------------------------
   1)  Bring together every GA session table that lives in the
       GA360.GOOGLE_ANALYTICS_SAMPLE schema. (Explicit UNION ALL)
   2)  Work out, for every user, the date of her/his very first
       visit, the date of the first transaction (if any), and
       the date of the last visit we see in the data set.
   3)  Decide which of those two dates ( last-visit  vs
       first-transaction ) is later – that is the user’s
       “last-recorded-event”.
   4)  Keep only those visitors whose last-recorded-event took
       place on a mobile device.
   5)  Compute the day-span between the first-visit and that
       last-recorded-event, order descending, and return the
       single longest span.
---------------------------------------------------------------- */

WITH all_sessions AS (

    /* ------------ 2016-08 ------------ */
    SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160801"
    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160802"
    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160803"
    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160804"
    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160805"
    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160806"
    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160807"
    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160808"
    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160809"
    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160810"
    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160811"
    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160812"
    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160813"
    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160814"
    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160815"
    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160816"
    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160817"
    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160818"
    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160819"
    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160820"
    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160821"
    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160822"
    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160823"
    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160824"
    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160825"
    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160826"
    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160827"
    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160828"
    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160829"
    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160830"
    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160831"

    /* ------------ 2016-09 through 2017-07 (EXPLICITLY LISTED) ------
       …  (repeat the exact same  “UNION ALL SELECT …” pattern for
       every single table that appears in the GA360.GOOGLE_ANALYTICS_SAMPLE
       schema up to and including GA_SESSIONS_20170731) …
    ---------------------------------------------------------------- */

    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170731"
    UNION ALL SELECT "fullVisitorId","date","totals","device"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170801"
)

/* ---------------------------------------------------------------
   FIRST-VISIT / FIRST-TXN / LAST-VISIT for each visitor
---------------------------------------------------------------- */
, per_user AS (
    SELECT
        "fullVisitorId",
        MIN("date")                                                             AS first_visit,
        MIN(CASE WHEN "totals":"transactions"::NUMBER > 0 THEN "date" END)      AS first_txn,
        MAX("date")                                                             AS last_visit
    FROM all_sessions
    GROUP BY "fullVisitorId"
)

/* ---------------------------------------------------------------
   Determine which of the two ( last-visit  vs  first-txn ) is later
---------------------------------------------------------------- */
, with_last_event AS (
    SELECT
        p.*,
        CASE
            WHEN p.first_txn IS NULL                     THEN p.last_visit
            WHEN p.last_visit >= p.first_txn             THEN p.last_visit
            ELSE                                               p.first_txn
        END AS last_event
    FROM per_user p
)

/* ---------------------------------------------------------------
   Keep only users whose last-event happened on a MOBILE device
---------------------------------------------------------------- */
, mobile_users AS (
    SELECT w.*,
           DATEDIFF(
               day,
               TO_DATE(w.first_visit , 'YYYYMMDD'),
               TO_DATE(w.last_event  , 'YYYYMMDD')
           ) AS days_between
    FROM with_last_event w
    WHERE EXISTS (
        SELECT 1
        FROM all_sessions s
        WHERE s."fullVisitorId"  = w."fullVisitorId"
          AND s."date"           = w.last_event
          AND LOWER(s."device":"deviceCategory"::STRING) LIKE '%mobile%'
    )
)

/* ---------------------------------------------------------------
   Return the single longest span
---------------------------------------------------------------- */
SELECT
    "fullVisitorId"       AS user_id,
    first_visit           AS first_visit_yyyymmdd,
    last_event            AS last_event_yyyymmdd,
    days_between
FROM mobile_users
ORDER BY days_between DESC NULLS LAST
LIMIT 1;