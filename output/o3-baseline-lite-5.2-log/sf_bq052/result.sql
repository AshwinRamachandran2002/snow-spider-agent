/* ------------------------------------------------------------
   U.S. patents that lie in CPC subsection ‘C05’  OR group ‘A01G’.
   For each such patent (identified by earliest valid application
   date in APPLICATION):
        • backward citations = earlier patents it cites whose
          application date is within one month before its own.
        • forward citations  = later patents that cite it whose
          application date is within one month after its own.
   Keep patents having ≥1 backward OR forward citation in those
   windows.  Return patent id, title, application date, the two
   citation counts, and abstract, ordered by application date.
------------------------------------------------------------ */
WITH
/* 1. earliest valid application date for every patent            */
app_dates AS (
    SELECT
        "patent_id",
        MIN(TRY_TO_DATE("date")) AS app_date
    FROM PATENTSVIEW.PATENTSVIEW."APPLICATION"
    WHERE TRY_TO_DATE("date") IS NOT NULL     -- discard malformed dates
    GROUP BY "patent_id"
),

/* 2. patents that fall in requested CPC classes                  */
cpc_patents AS (
    SELECT DISTINCT
        "patent_id"
    FROM PATENTSVIEW.PATENTSVIEW."CPC_CURRENT"
    WHERE "subsection_id" = 'C05'
       OR "group_id"      = 'A01G'
),

/* 3. base set = those CPC patents with their application date    */
base AS (
    SELECT
        cp."patent_id",
        ad.app_date
    FROM cpc_patents cp
    JOIN app_dates   ad ON ad."patent_id" = cp."patent_id"
),

/* 4. backward‑citation count: patents this one cites             */
backward_cte AS (
    SELECT
        b."patent_id",
        COUNT(DISTINCT uc."citation_id") AS backward_cnt
    FROM base                                    b
    JOIN PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" uc
         ON uc."patent_id" = b."patent_id"      -- current patent cites …
    JOIN app_dates cited
         ON cited."patent_id" = uc."citation_id" -- … that cited patent
    WHERE cited.app_date >= DATEADD(month,-1,b.app_date)
      AND cited.app_date  <  b.app_date
    GROUP BY b."patent_id"
),

/* 5. forward‑citation count: patents that cite the current one   */
forward_cte AS (
    SELECT
        b."patent_id",
        COUNT(DISTINCT uc."patent_id") AS forward_cnt
    FROM base                                    b
    JOIN PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" uc
         ON uc."citation_id" = b."patent_id"    -- another patent cites current
    JOIN app_dates citing
         ON citing."patent_id" = uc."patent_id" -- citing patent’s app date
    WHERE citing.app_date  >  b.app_date
      AND citing.app_date <= DATEADD(month,1,b.app_date)
    GROUP BY b."patent_id"
)

/* ---------------------------------------------------------------- */
SELECT
    b."patent_id"                                   AS patent_id,
    p."title",
    b.app_date                                      AS application_date,
    COALESCE(bw.backward_cnt,0)                     AS backward_citations_1m,
    COALESCE(fw.forward_cnt,0)                      AS forward_citations_1m,
    p."abstract"
FROM base                         b
JOIN PATENTSVIEW.PATENTSVIEW."PATENT" p
      ON p."id"      = b."patent_id"
     AND p."country" = 'US'                         -- ensure U.S. patents
LEFT JOIN backward_cte bw ON bw."patent_id" = b."patent_id"
LEFT JOIN forward_cte fw  ON fw."patent_id" = b."patent_id"
WHERE COALESCE(bw.backward_cnt,0) > 0
   OR COALESCE(fw.forward_cnt,0) > 0
ORDER BY b.app_date, b."patent_id";