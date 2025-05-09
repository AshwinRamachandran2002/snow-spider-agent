/*  Patents in CPC subsection C05 or group A01G
    – application date (US only)   (fixed date parsing)
    – # backward citations within 1 month before application
    – # forward  citations within 1 month after  application
    – abstract
*/
WITH "app" AS (   -- earliest valid U.S. application date for every patent
    SELECT
        "patent_id",
        MIN(
            TO_DATE(                       -- replace invalid “-00” day with “-01”
                REGEXP_REPLACE("date", '\\-00$', '-01'),
                'YYYY-MM-DD'
            )
        ) AS "app_date"
    FROM PATENTSVIEW.PATENTSVIEW.APPLICATION
    WHERE "country" = 'US'
      AND "date" IS NOT NULL
    GROUP BY "patent_id"
),
"cpc_filter" AS (   -- patents that fall in the requested CPC categories
    SELECT DISTINCT "patent_id"
    FROM PATENTSVIEW.PATENTSVIEW.CPC_CURRENT
    WHERE "subsection_id" = 'C05'
       OR "group_id"     = 'A01G'
),
"backward" AS (     -- citations to prior art filed ≤30 days earlier
    SELECT
        c."patent_id",
        COUNT(DISTINCT c."citation_id") AS "backward_cnt"
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION c
    JOIN "app" cur   ON cur."patent_id"   = c."patent_id"
    JOIN "app" cited ON cited."patent_id" = c."citation_id"
    WHERE DATEDIFF('day', cited."app_date", cur."app_date") BETWEEN 0 AND 30
    GROUP BY c."patent_id"
),
"forward" AS (      -- citations coming from patents filed ≤30 days later
    SELECT
        c."citation_id"                 AS "patent_id",
        COUNT(DISTINCT c."patent_id")   AS "forward_cnt"
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION c
    JOIN "app" cur    ON cur."patent_id"    = c."citation_id"
    JOIN "app" citing ON citing."patent_id" = c."patent_id"
    WHERE DATEDIFF('day', cur."app_date", citing."app_date") BETWEEN 0 AND 30
    GROUP BY c."citation_id"
)
SELECT
    p."id"                               AS "patent_id",
    p."title",
    a."app_date"                         AS "application_date",
    COALESCE(b."backward_cnt", 0)        AS "backward_citations_1m_prior",
    COALESCE(f."forward_cnt", 0)         AS "forward_citations_1m_after",
    p."abstract"
FROM PATENTSVIEW.PATENTSVIEW.PATENT p
JOIN "app"        a ON a."patent_id" = p."id"
JOIN "cpc_filter" c ON c."patent_id" = p."id"
LEFT JOIN "backward" b ON b."patent_id" = p."id"
LEFT JOIN "forward"  f ON f."patent_id" = p."id"
WHERE p."country" = 'US'
  AND (COALESCE(b."backward_cnt",0) > 0
       OR COALESCE(f."forward_cnt",0) > 0)
ORDER BY a."app_date" ASC NULLS LAST,
         p."id"       ASC;