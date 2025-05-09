/*  Retrieve the U.S. patent that
    • belongs to a chosen CPC category (example: group “G06F”),
    • has at least one backward citation whose application date is ≤ 1 year before its own application date,
    • has at least one forward citation whose application date is ≤ 1 year after its own application date,
    • and return the one with the largest number of such backward citations.
    Forward‑citation totals for the first 3 years are also reported.
*/
WITH focal AS (   -- all US patents in the CPC category, with their application date
    SELECT
        p."id"                              AS patent_id,
        MIN( TO_DATE(app."date") )          AS app_date
    FROM PATENTSVIEW.PATENTSVIEW.PATENT            p
    JOIN PATENTSVIEW.PATENTSVIEW.APPLICATION       app
          ON app."patent_id" = p."id"
    JOIN PATENTSVIEW.PATENTSVIEW.CPC_CURRENT       cpc
          ON cpc."patent_id" = p."id"
    WHERE p."country" = 'US'
      AND cpc."group_id" = 'G06F'                  -- <<–– specific CPC category
    GROUP BY p."id"
),
/* backward citations that were applied for within 1 year BEFORE the focal patent’s
   own application date                                                     */
backward AS (
    SELECT
        f.patent_id,
        COUNT(*) AS backward_1y_cnt
    FROM focal                                   f
    JOIN PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
         ON uc."patent_id" = f.patent_id               -- citations made BY focal patent
    JOIN PATENTSVIEW.PATENTSVIEW.APPLICATION app_cited
         ON app_cited."patent_id" = uc."citation_id"   -- cited patent’s app‑date
    WHERE TO_DATE(app_cited."date")
          BETWEEN DATEADD(year,-1, f.app_date)       -- ≤ 1 year before
              AND (f.app_date - INTERVAL '1 DAY')
    GROUP BY f.patent_id
),
/* forward citations (other patents that cite the focal patent)  */
forward AS (
    SELECT
        f.patent_id,
        COUNT( CASE
                 WHEN TO_DATE(app_citing."date")
                      <= DATEADD(year,1, f.app_date)
                 THEN 1 END
             )                                     AS forward_1y_cnt,
        COUNT(*)                                   AS forward_3y_cnt
    FROM focal                                   f
    JOIN PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
         ON uc."citation_id" = f.patent_id            -- citations TO the focal patent
    JOIN PATENTSVIEW.PATENTSVIEW.APPLICATION app_citing
         ON app_citing."patent_id" = uc."patent_id"   -- citing patent’s app‑date
    WHERE TO_DATE(app_citing."date")
          BETWEEN f.app_date
              AND DATEADD(year,3, f.app_date)         -- first 3 years window
    GROUP BY f.patent_id
),
combined AS (
    SELECT
        f.patent_id,
        COALESCE(b.backward_1y_cnt,0)  AS backward_1y_cnt,
        COALESCE(fr.forward_1y_cnt,0)  AS forward_1y_cnt,
        COALESCE(fr.forward_3y_cnt,0)  AS forward_3y_cnt
    FROM focal      f
    LEFT JOIN backward b ON b.patent_id = f.patent_id
    LEFT JOIN forward  fr ON fr.patent_id = f.patent_id
)
SELECT
    patent_id,
    backward_1y_cnt         AS "BACKWARD_CITATIONS_WITHIN_1_YEAR",
    forward_1y_cnt          AS "FORWARD_CITATIONS_WITHIN_1_YEAR",
    forward_3y_cnt          AS "FORWARD_CITATIONS_WITHIN_3_YEARS"
FROM combined
WHERE backward_1y_cnt > 0            -- must have qualifying backward citations
  AND forward_1y_cnt  > 0            -- must have qualifying forward citations
ORDER BY backward_1y_cnt DESC NULLS LAST, patent_id
LIMIT 1;