WITH base_patents AS (   /* earliest U.S. application date per patent */
    SELECT
        "patent_id",
        MIN(TRY_TO_DATE("date",'YYYY-MM-DD')) AS "application_date"
    FROM PATENTSVIEW.PATENTSVIEW."APPLICATION"
    WHERE "country" = 'US'
      AND TRY_TO_DATE("date",'YYYY-MM-DD') IS NOT NULL       -- drop bad dates
    GROUP BY "patent_id"
),
/* ── backward citations in the 1‑year window BEFORE filing ── */
backward_citations AS (
    SELECT
        u."patent_id",
        COUNT(*) AS "bwd_cnt_1y"
    FROM PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" u
    JOIN base_patents bp
      ON bp."patent_id" = u."patent_id"
    WHERE TRY_TO_DATE(u."date",'YYYY-MM-DD') IS NOT NULL
      AND TRY_TO_DATE(u."date",'YYYY-MM-DD')
          BETWEEN DATEADD(year,-1, bp."application_date")
              AND DATEADD(day,-1, bp."application_date")
    GROUP BY u."patent_id"
),
/* ── forward citations within 3 years AFTER filing ── */
forward_citations_3y AS (
    SELECT
        u."citation_id" AS "patent_id",
        COUNT(*)        AS "fwd_cnt_3y"
    FROM PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" u
    JOIN base_patents cited
      ON cited."patent_id" = u."citation_id"
    JOIN base_patents citing
      ON citing."patent_id" = u."patent_id"
    WHERE citing."application_date" >  cited."application_date"
      AND citing."application_date" <= DATEADD(year,3,cited."application_date")
    GROUP BY u."citation_id"
),
/* ── forward citations within 1 year AFTER filing ── */
forward_citations_1y AS (
    SELECT
        u."citation_id" AS "patent_id",
        COUNT(*)        AS "fwd_cnt_1y"
    FROM PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" u
    JOIN base_patents cited
      ON cited."patent_id" = u."citation_id"
    JOIN base_patents citing
      ON citing."patent_id" = u."patent_id"
    WHERE citing."application_date" >  cited."application_date"
      AND citing."application_date" <= DATEADD(year,1,cited."application_date")
    GROUP BY u."citation_id"
),
/* ── patents in desired CPC group(s) ── */
cpc_filtered AS (
    SELECT DISTINCT "patent_id"
    FROM PATENTSVIEW.PATENTSVIEW."CPC_CURRENT"
    WHERE "group_id" IN ('C12Y')            -- adjust CPC groups as needed
)
/* ── final result ── */
SELECT
    bp."patent_id",
    bp."application_date",
    bc."bwd_cnt_1y"  AS "backward_citations_1yr_before",
    fc3."fwd_cnt_3y" AS "forward_citations_3yrs_after",
    fc1."fwd_cnt_1y" AS "forward_citations_1yr_after"
FROM base_patents         bp
JOIN backward_citations   bc  ON bc."patent_id" = bp."patent_id"
JOIN forward_citations_3y fc3 ON fc3."patent_id" = bp."patent_id"
JOIN forward_citations_1y fc1 ON fc1."patent_id" = bp."patent_id"
JOIN cpc_filtered         cf  ON cf."patent_id" = bp."patent_id"
ORDER BY bc."bwd_cnt_1y" DESC NULLS LAST, bp."patent_id"
LIMIT 1;