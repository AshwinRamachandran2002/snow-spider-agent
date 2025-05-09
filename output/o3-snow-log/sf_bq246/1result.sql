/*  Retrieve the U.S. patent that
    • belongs to the selected CPC technology groups
    • has ≥1 backward citation whose cited-patent application date falls within
      1 year BEFORE its own application date
    • has ≥1 forward citation whose citing-patent application date falls within
      1 year AFTER its own application date
    • report the count of forward citations received within 3 years
    The single row returned is the patent with the greatest number of such
    backward citations.                                                     */

WITH cpc_filter AS (   -- patents in the CPC groups of interest
    SELECT DISTINCT "patent_id"
    FROM PATENTSVIEW.PATENTSVIEW.CPC_CURRENT
    WHERE "group_id" IN ('G06F','H04L','H01L')          -- << set groups here
),

backward AS (          -- citations ≤1 year BEFORE the patent’s application
    SELECT uc."patent_id",
           COUNT(*)                AS "backward_1yr"
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION   uc
    JOIN PATENTSVIEW.PATENTSVIEW.APPLICATION        app_citing
         ON uc."patent_id"   = app_citing."patent_id"
    JOIN PATENTSVIEW.PATENTSVIEW.APPLICATION        app_cited
         ON uc."citation_id" = app_cited."patent_id"
    WHERE TRY_TO_DATE(app_cited."date") BETWEEN
          DATEADD(year,-1,TRY_TO_DATE(app_citing."date"))
          AND DATEADD(day,-1,TRY_TO_DATE(app_citing."date"))
    GROUP BY uc."patent_id"
),

forward1 AS (          -- citations ≤1 year AFTER the patent’s application
    SELECT uc."citation_id"        AS "patent_id",
           COUNT(*)                AS "forward_1yr"
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION   uc
    JOIN PATENTSVIEW.PATENTSVIEW.APPLICATION        app_focal
         ON uc."citation_id" = app_focal."patent_id"
    JOIN PATENTSVIEW.PATENTSVIEW.APPLICATION        app_citing
         ON uc."patent_id"  = app_citing."patent_id"
    WHERE TRY_TO_DATE(app_citing."date") BETWEEN
          DATEADD(day,1,TRY_TO_DATE(app_focal."date"))
          AND DATEADD(year,1,TRY_TO_DATE(app_focal."date"))
    GROUP BY uc."citation_id"
),

forward3 AS (          -- citations ≤3 years AFTER the patent’s application
    SELECT uc."citation_id"        AS "patent_id",
           COUNT(*)                AS "forward_3yr"
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION   uc
    JOIN PATENTSVIEW.PATENTSVIEW.APPLICATION        app_focal
         ON uc."citation_id" = app_focal."patent_id"
    JOIN PATENTSVIEW.PATENTSVIEW.APPLICATION        app_citing
         ON uc."patent_id"  = app_citing."patent_id"
    WHERE TRY_TO_DATE(app_citing."date") BETWEEN
          DATEADD(day,1,TRY_TO_DATE(app_focal."date"))
          AND DATEADD(year,3,TRY_TO_DATE(app_focal."date"))
    GROUP BY uc."citation_id"
)

SELECT b."patent_id",
       b."backward_1yr",
       f3."forward_3yr"
FROM   backward  b
JOIN   forward1  f1 ON b."patent_id" = f1."patent_id"          -- ensure ≥1 forward-1 yr
JOIN   forward3  f3 ON b."patent_id" = f3."patent_id"
JOIN   cpc_filter c ON b."patent_id" = c."patent_id"           -- CPC filter
ORDER BY b."backward_1yr" DESC NULLS LAST
LIMIT 1;