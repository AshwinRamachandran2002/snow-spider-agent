WITH curr_patents AS (   -- U.S. patents with their application dates
    SELECT 
        p."id"                        AS patent_id ,
        p."number"                    AS patent_number ,
        TO_DATE(app."date")           AS app_date
    FROM PATENTSVIEW.PATENTSVIEW."PATENT"      p
    JOIN PATENTSVIEW.PATENTSVIEW."APPLICATION" app
          ON app."patent_id" = p."id"
    WHERE p."country" = 'US'
), 

cpc_scope AS (          -- patents that fall in the chosen CPC groups
    SELECT DISTINCT "patent_id"
    FROM PATENTSVIEW.PATENTSVIEW."CPC_CURRENT"
    WHERE "group_id" IN ('G06F','H04L')        -- <<===  set desired CPC groups
), 

backward_1yr AS (       -- backward citations made ≤ 1 year before filing
    SELECT 
        cp.patent_id ,
        COUNT( DISTINCT uc."citation_id") AS back_cnt_1yr
    FROM curr_patents                    cp
    JOIN PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" uc
          ON uc."patent_id" = cp.patent_id          -- current → earlier
    JOIN PATENTSVIEW.PATENTSVIEW."APPLICATION" cited_app
          ON cited_app."patent_id" = uc."citation_id"
    WHERE TO_DATE(cited_app."date") 
          BETWEEN DATEADD(year,-1,cp.app_date) AND cp.app_date
    GROUP BY cp.patent_id
), 

forward_3yr AS (        -- forward citations received ≤ 3 years after filing
    SELECT 
        cp.patent_id ,
        COUNT( DISTINCT uc."patent_id") AS fwd_cnt_3yr
    FROM curr_patents                    cp
    JOIN PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" uc
          ON uc."citation_id" = cp.patent_id        -- later → current
    JOIN PATENTSVIEW.PATENTSVIEW."APPLICATION" citing_app
          ON citing_app."patent_id" = uc."patent_id"
    WHERE TO_DATE(citing_app."date")
          BETWEEN cp.app_date AND DATEADD(year,3,cp.app_date)
    GROUP BY cp.patent_id
), 

forward_1yr AS (        -- need at least one forward citation within 1 year
    SELECT 
        cp.patent_id ,
        COUNT( DISTINCT uc."patent_id") AS fwd_cnt_1yr
    FROM curr_patents                    cp
    JOIN PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" uc
          ON uc."citation_id" = cp.patent_id
    JOIN PATENTSVIEW.PATENTSVIEW."APPLICATION" citing_app
          ON citing_app."patent_id" = uc."patent_id"
    WHERE TO_DATE(citing_app."date")
          BETWEEN cp.app_date AND DATEADD(year,1,cp.app_date)
    GROUP BY cp.patent_id
)

SELECT 
    cp.patent_id ,
    cp.patent_number ,
    b.back_cnt_1yr        AS backward_citations_within_1yr ,
    f3.fwd_cnt_3yr        AS forward_citations_within_3yrs
FROM curr_patents cp
JOIN cpc_scope  cpc  ON cpc."patent_id" = cp.patent_id       -- CPC filter
JOIN backward_1yr b ON b.patent_id     = cp.patent_id        -- has ≥1 back‑cit ≤1 yr
JOIN forward_1yr f1 ON f1.patent_id    = cp.patent_id        -- has ≥1 fwd‑cit ≤1 yr
JOIN forward_3yr f3 ON f3.patent_id    = cp.patent_id        -- get 3‑yr fwd count
ORDER BY b.back_cnt_1yr DESC NULLS LAST
LIMIT 1;