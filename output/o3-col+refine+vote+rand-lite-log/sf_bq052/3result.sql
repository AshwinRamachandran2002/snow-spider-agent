/*  Patents in CPC subsection C05 or group A01G
    - Handle malformed application-date values with TRY_TO_DATE               */

WITH app AS (      /* earliest valid U.S. application date for every patent */
    SELECT  "patent_id",
            MIN(TRY_TO_DATE("date",'YYYY-MM-DD')) AS "app_date"
    FROM    PATENTSVIEW.PATENTSVIEW.APPLICATION
    GROUP BY "patent_id"
    HAVING  MIN(TRY_TO_DATE("date",'YYYY-MM-DD')) IS NOT NULL
),
cpc_filter AS (    /* patents that fall in requested CPC classes             */
    SELECT DISTINCT "patent_id"
    FROM   PATENTSVIEW.PATENTSVIEW.CPC_CURRENT
    WHERE  "subsection_id" = 'C05'
       OR  "group_id"      = 'A01G'
),
/* backward citations: focal patent → cited patent (within 30 days before)   */
bw AS (
    SELECT  uc."patent_id",
            COUNT(DISTINCT uc."citation_id") AS bw_cnt
    FROM    PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
    JOIN    app  fp     ON fp."patent_id"     = uc."patent_id"
    JOIN    app  cited  ON cited."patent_id"  = uc."citation_id"
    WHERE   cited."app_date" >= fp."app_date" - INTERVAL '30 day'
      AND   cited."app_date" <  fp."app_date"
    GROUP BY uc."patent_id"
),
/* forward citations: citing patent → focal patent (within 30 days after)    */
fw AS (
    SELECT  uc."citation_id"                    AS "patent_id",
            COUNT(DISTINCT uc."patent_id")      AS fw_cnt
    FROM    PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
    JOIN    app focal   ON focal."patent_id"  = uc."citation_id"
    JOIN    app citing  ON citing."patent_id" = uc."patent_id"
    WHERE   citing."app_date" >  focal."app_date"
      AND   citing."app_date" <= focal."app_date" + INTERVAL '30 day'
    GROUP BY uc."citation_id"
)
SELECT  p."id"                             AS "patent_id",
        p."title",
        app."app_date"                     AS "application_date",
        COALESCE(bw.bw_cnt,0)              AS "backward_1m_cnt",
        COALESCE(fw.fw_cnt,0)              AS "forward_1m_cnt",
        p."abstract"
FROM    PATENTSVIEW.PATENTSVIEW.PATENT p
JOIN    cpc_filter                  cf   ON p."id" = cf."patent_id"
JOIN    app                         app  ON p."id" = app."patent_id"
LEFT JOIN bw                        ON p."id" = bw."patent_id"
LEFT JOIN fw                        ON p."id" = fw."patent_id"
WHERE   COALESCE(bw.bw_cnt,0) > 0
     OR COALESCE(fw.fw_cnt,0) > 0
ORDER BY app."app_date";