/* -------- 0. helper : robust date parsing ---------------------------------*/
WITH helper_dates AS (
    SELECT
        "citation_id",
        "patent_id",
        /* normalise yyyymm00 or yyyymmdd (day unknown => set to 01)          */
        COALESCE(
            TRY_TO_DATE("date"),                       -- e.g. 2010-05-18
            TRY_TO_DATE(CONCAT(SUBSTR("date",1,8),'01'))  -- e.g. 20100500
        ) AS "clean_date"
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION
    WHERE "date" IS NOT NULL
),

/* -------- 1. earliest U.S. application date for every patent --------------*/
app AS (
    SELECT
        "patent_id",
        MIN(
            COALESCE(
                TRY_TO_DATE("date"),
                TRY_TO_DATE(CONCAT(SUBSTR("date",1,8),'01'))
            )
        ) AS "app_date"
    FROM PATENTSVIEW.PATENTSVIEW.APPLICATION
    WHERE "country" = 'US'
      AND "date"   IS NOT NULL
    GROUP BY "patent_id"
),

/* -------- 2. restrict to requested CPC categories -------------------------*/
filtered_patents AS (
    SELECT DISTINCT
        a."patent_id",
        a."app_date"
    FROM app a
    JOIN PATENTSVIEW.PATENTSVIEW.CPC_CURRENT c
          ON c."patent_id" = a."patent_id"
    WHERE c."subsection_id" = 'C05'          /* fertilisers etc.  */
       OR c."group_id"      = 'A01G'         /* horticulture group */
),

/* -------- 3a. citations made BY the focal patent  (backward) --------------*/
cit_out AS (
    SELECT
        h."patent_id"                   AS "patent_id",      -- focal patent
        h."citation_id"                 AS "other_patent",
        h."clean_date"                  AS "cite_date"
    FROM helper_dates h
    WHERE h."clean_date" IS NOT NULL
),

/* -------- 3b. citations received BY the focal patent (forward) -------------*/
cit_in AS (
    SELECT
        h."citation_id"                 AS "patent_id",      -- focal patent
        h."patent_id"                   AS "other_patent",
        h."clean_date"                  AS "cite_date"
    FROM helper_dates h
    WHERE h."clean_date" IS NOT NULL
),

/* -------- 4. count citations in ±1‑month windows --------------------------*/
counts AS (
    SELECT
        fp."patent_id",

        /* backward: patents the focal patent cites within 1 month before its
           own application date                                               */
        COUNT(DISTINCT CASE
              WHEN co."cite_date" >= DATEADD(month,-1, fp."app_date")
               AND co."cite_date" <  fp."app_date"
              THEN co."other_patent" END)                      AS "backward_citations_1m",

        /* forward: patents that cite the focal patent within 1 month after
           the focal patent’s application date                                */
        COUNT(DISTINCT CASE
              WHEN ci."cite_date" >  fp."app_date"
               AND ci."cite_date" <= DATEADD(month, 1, fp."app_date")
              THEN ci."other_patent" END)                      AS "forward_citations_1m"
    FROM filtered_patents fp
    LEFT JOIN cit_out co ON co."patent_id" = fp."patent_id"
    LEFT JOIN cit_in  ci ON ci."patent_id" = fp."patent_id"
    GROUP BY fp."patent_id"
),

/* -------- 5. final assembly ----------------------------------------------*/
final AS (
    SELECT
        fp."patent_id",
        p."title",
        fp."app_date"                              AS "application_date",
        COALESCE(c."backward_citations_1m",0)      AS "backward_citations_1m",
        COALESCE(c."forward_citations_1m",0)       AS "forward_citations_1m",
        p."abstract"
    FROM filtered_patents fp
    JOIN counts c   ON c."patent_id" = fp."patent_id"
    JOIN PATENTSVIEW.PATENTSVIEW.PATENT p
         ON p."id" = fp."patent_id"
    /* keep only patents with at least one citation in either 1‑month window */
    WHERE COALESCE(c."backward_citations_1m",0) > 0
       OR COALESCE(c."forward_citations_1m",0)  > 0
)

SELECT *
FROM final
ORDER BY "application_date", "patent_id";