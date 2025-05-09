WITH filing_dates AS (            -- earliest valid filing date for every patent
    SELECT  a."patent_id"                         AS PATENT_ID,
            MIN(TRY_TO_DATE(a."date"))            AS FILING_DATE
    FROM    PATENTSVIEW.PATENTSVIEW.APPLICATION a
    WHERE   TRY_TO_DATE(a."date") IS NOT NULL
    GROUP BY a."patent_id"
),
target_patents AS (               -- patents filed 1‑Jan‑2014 – 1‑Feb‑2014
    SELECT  PATENT_ID,
            FILING_DATE
    FROM    filing_dates
    WHERE   FILING_DATE BETWEEN '2014-01-01' AND '2014-02-01'
),
patent_info AS (                  -- publication data for all U.S. patents
    SELECT  p."id"                            AS PATENT_ID,
            p."title"                         AS TITLE,
            p."abstract"                      AS ABSTRACT,
            TRY_TO_DATE(p."date")             AS PUB_DATE
    FROM    PATENTSVIEW.PATENTSVIEW.PATENT p
    WHERE   p."country" = 'US'
      AND   TRY_TO_DATE(p."date") IS NOT NULL
),
bio_chem_patents AS (             -- keep only chemistry / biology / medical CPC
    SELECT DISTINCT
            pi.PATENT_ID,
            pi.TITLE,
            pi.ABSTRACT,
            pi.PUB_DATE
    FROM    patent_info pi
    JOIN    target_patents tp
           ON tp.PATENT_ID = pi.PATENT_ID
    JOIN    PATENTSVIEW.PATENTSVIEW.CPC_CURRENT cpc
           ON cpc."patent_id" = pi.PATENT_ID
    WHERE   ( cpc."subsection_id" BETWEEN 'C05' AND 'C13'
           OR cpc."group_id" IN ('A01G','A01H','A61K','A61P','A61Q',
                                 'B01F','B01J','B81B','B82B','B82Y',
                                 'G01N','G16H') )
),
backward AS (                     -- patents cited BEFORE the filing date
    SELECT  bp.PATENT_ID,
            COUNT(DISTINCT uc."citation_id")  AS BACKWARD_CITATIONS
    FROM    bio_chem_patents bp
    JOIN    target_patents tp
           ON tp.PATENT_ID = bp.PATENT_ID
    LEFT JOIN PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
           ON uc."patent_id" = bp.PATENT_ID
    WHERE   TRY_TO_DATE(uc."date") IS NOT NULL
      AND   TRY_TO_DATE(uc."date") < tp.FILING_DATE
    GROUP BY bp.PATENT_ID
),
forward AS (                      -- patents that cite within 5 years after pub.
    SELECT  bp.PATENT_ID,
            COUNT(DISTINCT uc."patent_id")    AS FORWARD_CITATIONS_5YR
    FROM    bio_chem_patents bp
    LEFT JOIN PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
           ON uc."citation_id" = bp.PATENT_ID
    LEFT JOIN patent_info p2                  -- citing patent publication date
           ON p2.PATENT_ID = uc."patent_id"
    WHERE   p2.PUB_DATE IS NOT NULL
      AND   p2.PUB_DATE >= bp.PUB_DATE
      AND   p2.PUB_DATE <= DATEADD(year, 5, bp.PUB_DATE)
    GROUP BY bp.PATENT_ID
)
SELECT  bp.TITLE                                 AS patent_title,
        bp.ABSTRACT                              AS abstract,
        bp.PUB_DATE                              AS publication_date,
        COALESCE(b.BACKWARD_CITATIONS, 0)        AS backward_citations,
        COALESCE(f.FORWARD_CITATIONS_5YR, 0)     AS forward_citations_5yr
FROM    bio_chem_patents bp
LEFT JOIN backward b ON b.PATENT_ID = bp.PATENT_ID
LEFT JOIN forward  f ON f.PATENT_ID = bp.PATENT_ID
ORDER BY bp.PUB_DATE, bp.PATENT_ID;