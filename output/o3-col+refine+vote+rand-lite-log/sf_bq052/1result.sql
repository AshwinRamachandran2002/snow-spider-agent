/*  Patents in CPC subsection ‘C05’ or group ‘A01G’ that have at least one
    backward citation in the 30 days BEFORE the application date or one
    forward citation in the 30 days AFTER the application date              */

WITH cpc_filter AS (         -- patents belonging to the requested CPC areas
    SELECT DISTINCT "patent_id"
    FROM   PATENTSVIEW.PATENTSVIEW.CPC_CURRENT
    WHERE  "subsection_id" = 'C05'
       OR  "group_id"      = 'A01G'
),

apps AS (                    -- parse & keep usable application dates
    SELECT  "patent_id",
            TRY_TO_DATE("date") AS "app_date"
    FROM    PATENTSVIEW.PATENTSVIEW.APPLICATION
    WHERE   TRY_TO_DATE("date") IS NOT NULL
),

backward AS (                -- citations MADE by the patent ≤30 days before filing
    SELECT  u."patent_id",
            COUNT(*) AS "bwd_cnt"
    FROM    PATENTSVIEW.PATENTSVIEW.USPATENTCITATION u
    JOIN    apps a
           ON a."patent_id" = u."patent_id"
    WHERE   TRY_TO_DATE(u."date") IS NOT NULL
      AND   TRY_TO_DATE(u."date") <  a."app_date"
      AND   DATEDIFF('day', TRY_TO_DATE(u."date"), a."app_date") BETWEEN 0 AND 30
    GROUP BY u."patent_id"
),

forward AS (                 -- citations RECEIVED by the patent ≤30 days after filing
    SELECT  u."citation_id"       AS "patent_id",
            COUNT(*)              AS "fwd_cnt"
    FROM    PATENTSVIEW.PATENTSVIEW.USPATENTCITATION u
    JOIN    apps a
           ON a."patent_id" = u."citation_id"
    WHERE   TRY_TO_DATE(u."date") IS NOT NULL
      AND   TRY_TO_DATE(u."date") >  a."app_date"
      AND   DATEDIFF('day', a."app_date", TRY_TO_DATE(u."date")) BETWEEN 0 AND 30
    GROUP BY u."citation_id"
)

SELECT
       p."id"                           AS "patent_id",
       p."title",
       a."app_date"                     AS "application_date",
       COALESCE(b."bwd_cnt", 0)         AS "backward_30d_cnt",
       COALESCE(f."fwd_cnt", 0)         AS "forward_30d_cnt",
       p."abstract"
FROM   PATENTSVIEW.PATENTSVIEW.PATENT  p
JOIN   cpc_filter               cf ON p."id" = cf."patent_id"
JOIN   apps                     a  ON p."id" = a."patent_id"
LEFT   JOIN backward            b  ON p."id" = b."patent_id"
LEFT   JOIN forward             f  ON p."id" = f."patent_id"
WHERE  COALESCE(b."bwd_cnt", 0) > 0       -- keep patents with at least one windowed citation
    OR COALESCE(f."fwd_cnt", 0) > 0
ORDER BY a."app_date";