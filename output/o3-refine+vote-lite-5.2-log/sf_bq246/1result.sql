/*  Patents in CPC group G06F (digital data processing) that                         */
/*  – have ≥1 backward citation whose application date falls within 1 year          */
/*    before the patent’s own application date,                                     */
/*  – have ≥1 forward citation whose application date falls within 1 year           */
/*    after the patent’s own application date,                                      */
/*  – and returns the single patent with the highest number of such backward        */
/*    citations, together with its forward‑citation count within 3 years.           */

WITH cpc_us_patents AS (          -- U.S. patents in the chosen CPC category
    SELECT DISTINCT
           p."id"                AS patent_id,
           TO_DATE(a."date")     AS app_date
    FROM PATENTSVIEW.PATENTSVIEW.PATENT        p
    JOIN PATENTSVIEW.PATENTSVIEW.APPLICATION   a   ON a."patent_id" = p."id"
    JOIN PATENTSVIEW.PATENTSVIEW.CPC_CURRENT   cpc ON cpc."patent_id" = p."id"
    WHERE p."country" = 'US'
      AND cpc."group_id" IN ('G06F')           -- << choose desired CPC group(s)
),

/* backward citations within 1 year BEFORE application date */
backward_cte AS (
    SELECT
        cp.patent_id,
        COUNT(*) AS backward_1yr_cnt
    FROM cpc_us_patents                       cp
    JOIN PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
         ON uc."patent_id" = cp.patent_id               -- current patent cites “citation_id”
    JOIN PATENTSVIEW.PATENTSVIEW.APPLICATION   cited_app
         ON cited_app."patent_id" = uc."citation_id"
    WHERE TO_DATE(cited_app."date") >= DATEADD(year,-1, cp.app_date)
      AND TO_DATE(cited_app."date")  <  cp.app_date
    GROUP BY cp.patent_id
),

/* forward citations: patents that cite the current one */
forward_cte AS (
    SELECT
        cp.patent_id,
        COUNT( CASE
                 WHEN TO_DATE(citing_app."date") <= DATEADD(year,1 ,cp.app_date)
                 THEN 1 END )                                     AS forward_1yr_cnt,
        COUNT( CASE
                 WHEN TO_DATE(citing_app."date") <= DATEADD(year,3 ,cp.app_date)
                 THEN 1 END )                                     AS forward_3yr_cnt
    FROM cpc_us_patents                         cp
    JOIN PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
         ON uc."citation_id" = cp.patent_id               -- other patent cites current
    JOIN PATENTSVIEW.PATENTSVIEW.APPLICATION     citing_app
         ON citing_app."patent_id" = uc."patent_id"
    WHERE TO_DATE(citing_app."date") >= cp.app_date
      AND TO_DATE(citing_app."date") <= DATEADD(year,3, cp.app_date)
    GROUP BY cp.patent_id
),

/* combine & filter for required conditions */
eligible AS (
    SELECT
        b.patent_id,
        b.backward_1yr_cnt,
        f.forward_1yr_cnt,
        f.forward_3yr_cnt
    FROM backward_cte b
    JOIN forward_cte  f ON f.patent_id = b.patent_id      -- guarantees ≥1 backward citation
    WHERE f.forward_1yr_cnt > 0                           -- need ≥1 forward citation in 1 yr
)

SELECT
    patent_id                                           AS "PATENT_ID",
    backward_1yr_cnt                                   AS "BACKWARD_CITATIONS_WITHIN_1YR",
    forward_3yr_cnt                                    AS "FORWARD_CITATIONS_WITHIN_3YRS"
FROM eligible
ORDER BY backward_1yr_cnt DESC NULLS LAST, patent_id    -- most backward citations first
LIMIT 1;