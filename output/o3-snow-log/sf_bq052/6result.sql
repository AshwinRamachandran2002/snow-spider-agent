/* ----------  PREP: cleanly parse all application dates ---------- */
WITH app_dates AS (             -- one (parsed) application date per patent
    SELECT
        a."patent_id",
        MIN( TRY_TO_DATE(a."date",'YYYY-MM-DD') )  AS application_date
    FROM PATENTSVIEW.PATENTSVIEW.APPLICATION a
    GROUP BY a."patent_id"
),

/* ---------- 1) patents of interest (US + chosen CPC classes) ------- */
base_patents AS (
    SELECT
        p."id"           AS patent_id,
        p."title"        AS title,
        ad.application_date,
        p."abstract"     AS abstract
    FROM PATENTSVIEW.PATENTSVIEW.PATENT       p
    JOIN app_dates                              ad  ON ad."patent_id" = p."id"
    JOIN PATENTSVIEW.PATENTSVIEW.CPC_CURRENT   c   ON c."patent_id" = p."id"
    WHERE p."country" = 'US'
      AND ad.application_date IS NOT NULL
      AND ( c."subsection_id" = 'C05'      -- keep subsection C05
            OR c."group_id"    = 'A01G' )  -- or group A01G
    GROUP BY p."id", p."title", ad.application_date, p."abstract"
),

/* ---------- 2) backward-citation counts (≤ 1 month before) -------- */
backward_ct AS (
    SELECT
        bp.patent_id,
        COUNT( DISTINCT uc."citation_id" )   AS backward_cnt
    FROM base_patents bp
    JOIN PATENTSVIEW.PATENTSVIEW.USPATENTCITATION   uc
           ON uc."patent_id" = bp.patent_id       -- bp cites uc.citation_id
    JOIN app_dates               ad_cited
           ON ad_cited."patent_id" = uc."citation_id"
    WHERE ad_cited.application_date IS NOT NULL
      AND ad_cited.application_date
            BETWEEN DATEADD(month,-1 , bp.application_date)
                AND DATEADD(day  ,-1 , bp.application_date)   -- strictly before
    GROUP BY bp.patent_id
),

/* ---------- 3) forward-citation counts (≤ 1 month after) ---------- */
forward_ct AS (
    SELECT
        bp.patent_id,
        COUNT( DISTINCT uc."patent_id" )     AS forward_cnt
    FROM base_patents bp
    JOIN PATENTSVIEW.PATENTSVIEW.USPATENTCITATION   uc
           ON uc."citation_id" = bp.patent_id       -- later patent cites bp
    JOIN app_dates               ad_citing
           ON ad_citing."patent_id" = uc."patent_id"
    WHERE ad_citing.application_date IS NOT NULL
      AND ad_citing.application_date
            BETWEEN DATEADD(day , 1 , bp.application_date)    -- strictly after
                AND DATEADD(month,1 , bp.application_date)
    GROUP BY bp.patent_id
),

/* ---------- 4) assemble results, keep patents with ≥1 such citation --------- */
combined AS (
    SELECT
        bp.patent_id,
        bp.title,
        bp.application_date,
        COALESCE(b.backward_cnt , 0)  AS backward_citations_1m_before,
        COALESCE(f.forward_cnt  , 0)  AS forward_citations_1m_after,
        bp.abstract
    FROM base_patents  bp
    LEFT JOIN backward_ct b ON b.patent_id = bp.patent_id
    LEFT JOIN forward_ct  f ON f.patent_id = bp.patent_id
)

SELECT
    patent_id,
    title,
    TO_CHAR(application_date,'YYYY-MM-DD')  AS application_date,
    backward_citations_1m_before,
    forward_citations_1m_after,
    abstract
FROM combined
WHERE backward_citations_1m_before > 0
   OR forward_citations_1m_after  > 0
ORDER BY application_date;