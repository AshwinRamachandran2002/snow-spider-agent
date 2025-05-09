/* 1.  Gather every event of interest from ACTIVITY_LOG                   */
WITH base AS ( 
    SELECT  "session",
            "stamp",
            "path",
            "search_type"
    FROM    LOG.LOG.ACTIVITY_LOG
),

/* 2.  First time in each session a “/detail” (click) or “/complete”     */
first_target AS (
    SELECT  "session",
            MIN( CASE
                     WHEN "path" ILIKE '%/detail%' 
                      OR "path" ILIKE '%/complete%' 
                 THEN "stamp"
                 END )                       AS "first_target_stamp"
    FROM    base
    GROUP BY "session"
),

/* 3.  Events that happened BEFORE that first target and have search_type */
pre_events AS (
    SELECT  b."session",
            b."stamp",
            b."path",
            b."search_type",
            f."first_target_stamp"
    FROM    base b
    LEFT JOIN first_target f
           ON b."session" = f."session"
    WHERE   b."search_type" <> ''
      AND  ( f."first_target_stamp" IS NULL 
             OR b."stamp" < f."first_target_stamp" )
),

/* 4.  Count such events per session                                     */
pre_cnt AS (
    SELECT  "session",
            COUNT(*) AS "pre_target_cnt"
    FROM    pre_events
    GROUP BY "session"
),

/* 5.  Minimum count over all sessions                                   */
min_cnt AS (
    SELECT  MIN("pre_target_cnt") AS "min_pre_target_cnt"
    FROM    pre_cnt
),

/* 6.  Sessions that share that minimum                                  */
target_sessions AS (
    SELECT  p."session"
    FROM    pre_cnt p
    JOIN    min_cnt m
          ON p."pre_target_cnt" = m."min_pre_target_cnt"
),

/* 7.  Pick (earliest) representative row per qualifying session          */
ranked AS (
    SELECT  b."session",
            b."path",
            b."search_type",
            ROW_NUMBER() OVER (PARTITION BY b."session" 
                               ORDER BY b."stamp") AS rn
    FROM    base b
    JOIN    target_sessions t
          ON b."session" = t."session"
    WHERE   b."search_type" <> ''
)

SELECT  "session",
        "path",
        "search_type"
FROM    ranked
WHERE   rn = 1
ORDER BY "session";