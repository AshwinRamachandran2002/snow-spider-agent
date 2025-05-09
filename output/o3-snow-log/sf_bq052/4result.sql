WITH app_dates AS (   /* earliest valid application date per patent */
    SELECT
        "patent_id",
        MIN(TRY_TO_DATE("date")) AS "app_date"
    FROM PATENTSVIEW.PATENTSVIEW.APPLICATION
    GROUP BY "patent_id"
    HAVING MIN(TRY_TO_DATE("date")) IS NOT NULL            -- keep patents with at least one valid date
),

cpc_filtered AS (      /* patents in the requested CPC scopes */
    SELECT DISTINCT
        "patent_id"
    FROM PATENTSVIEW.PATENTSVIEW.CPC_CURRENT
    WHERE "subsection_id" = 'C05'
       OR "group_id"      = 'A01G'
),

base_patents AS (      /* basic patent info restricted to CPC list */
    SELECT
        p."id"           AS "patent_id",
        p."title",
        a."app_date",
        p."abstract"
    FROM PATENTSVIEW.PATENTSVIEW.PATENT p
    JOIN app_dates       a ON a."patent_id" = p."id"
    JOIN cpc_filtered    c ON c."patent_id" = p."id"
),

backward_counts AS (   /* citations made by the patent within 1-month window before its own app date */
    SELECT
        c."patent_id"                        AS "patent_id",
        COUNT(*)                             AS "backward_cnt"
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION c
    JOIN app_dates curr   ON curr."patent_id"  = c."patent_id"     -- citing patent
    JOIN app_dates cited  ON cited."patent_id" = c."citation_id"   -- cited patent
    WHERE cited."app_date" >= DATEADD(month, -1, curr."app_date")
      AND cited."app_date" <  curr."app_date"
    GROUP BY c."patent_id"
),

forward_counts AS (    /* citations received by the patent within 1-month window after its own app date */
    SELECT
        c."citation_id"                      AS "patent_id",
        COUNT(*)                             AS "forward_cnt"
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION c
    JOIN app_dates curr   ON curr."patent_id"  = c."citation_id"   -- cited patent
    JOIN app_dates citing ON citing."patent_id" = c."patent_id"    -- citing patent
    WHERE citing."app_date" >  curr."app_date"
      AND citing."app_date" <= DATEADD(month, 1, curr."app_date")
    GROUP BY c."citation_id"
)

SELECT
    bp."patent_id",
    bp."title",
    bp."app_date"                                   AS "application_date",
    COALESCE(bc."backward_cnt", 0)                  AS "backward_citations_1m_before",
    COALESCE(fc."forward_cnt", 0)                   AS "forward_citations_1m_after",
    bp."abstract"
FROM base_patents  bp
LEFT JOIN backward_counts bc ON bc."patent_id" = bp."patent_id"
LEFT JOIN forward_counts fc ON fc."patent_id" = bp."patent_id"
WHERE COALESCE(bc."backward_cnt", 0) > 0
   OR COALESCE(fc."forward_cnt", 0) > 0
ORDER BY bp."app_date";