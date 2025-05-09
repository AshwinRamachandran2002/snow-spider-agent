/*  Retrieve the U.S. patent that
    • belongs to CPC sections G or H
    • has at least one backward citation within the single year before its own U.S. application date
    • has at least one forward citation within the single year after its own U.S. application date
      (→ filter via the fwd1 CTE)
    • counts all forward citations made within three years after its application date
      (→ fwd3 CTE, whose total is returned)
    The result is ordered by the backward–citation count and the single
    top patent is returned.
*/
WITH app AS (
    SELECT  "patent_id",
            TRY_TO_DATE("date") AS "app_date"
    FROM    PATENTSVIEW.PATENTSVIEW.APPLICATION
    WHERE   "country" = 'US'
      AND   TRY_TO_DATE("date") IS NOT NULL
), ------------------------------------------------------------------
back AS (   -- backward citations ≤ 1 yr before the focal application
    SELECT  c."patent_id",
            COUNT(*) AS "back_cnt"
    FROM    PATENTSVIEW.PATENTSVIEW.USPATENTCITATION c
    JOIN    app citing ON citing."patent_id"  = c."patent_id"
    JOIN    app cited  ON cited."patent_id"   = c."citation_id"
    WHERE   cited."app_date"
            BETWEEN DATEADD(year,-1,citing."app_date") AND citing."app_date"
    GROUP BY c."patent_id"
), ------------------------------------------------------------------
fwd1 AS (   -- forward citations ≤ 1 yr after the focal application
    SELECT  c."citation_id"  AS "patent_id",
            COUNT(*)         AS "fwd1_cnt"
    FROM    PATENTSVIEW.PATENTSVIEW.USPATENTCITATION c
    JOIN    app focal  ON focal."patent_id"  = c."citation_id"
    JOIN    app citing ON citing."patent_id" = c."patent_id"
    WHERE   citing."app_date"
            BETWEEN focal."app_date" AND DATEADD(year,1,focal."app_date")
    GROUP BY c."citation_id"
), ------------------------------------------------------------------
fwd3 AS (   -- forward citations ≤ 3 yrs after the focal application
    SELECT  c."citation_id"  AS "patent_id",
            COUNT(*)         AS "fwd3_cnt"
    FROM    PATENTSVIEW.PATENTSVIEW.USPATENTCITATION c
    JOIN    app focal  ON focal."patent_id"  = c."citation_id"
    JOIN    app citing ON citing."patent_id" = c."patent_id"
    WHERE   citing."app_date"
            BETWEEN focal."app_date" AND DATEADD(year,3,focal."app_date")
    GROUP BY c."citation_id"
), ------------------------------------------------------------------
tech AS (   -- patents belonging to the requested CPC technology areas
    SELECT DISTINCT "patent_id"
    FROM   PATENTSVIEW.PATENTSVIEW.CPC_CURRENT
    WHERE  "section_id" IN ('G','H')      -- << adjust CPC filter here
) --------------------------------------------------------------------
SELECT  b."patent_id",
        b."back_cnt",
        f3."fwd3_cnt"
FROM        back  b
JOIN        fwd1  f1  ON f1."patent_id" = b."patent_id"   -- ensures ≥1 fwd-cit within 1 yr
JOIN        fwd3  f3  ON f3."patent_id" = b."patent_id"
JOIN        tech  t   ON t."patent_id"  = b."patent_id"
ORDER BY    b."back_cnt" DESC NULLS LAST
LIMIT 1;