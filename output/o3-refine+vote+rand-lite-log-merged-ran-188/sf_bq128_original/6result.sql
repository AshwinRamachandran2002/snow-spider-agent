WITH PAT_APP AS (   /* earliest U.S. filing date & publication date, using safe date parsing */
    SELECT
        p."id"                                            AS patent_id,
        p."title",
        p."abstract",
        TRY_TO_DATE(p."date")                             AS publication_date,
        MIN(TRY_TO_DATE(a."date"))                        AS filing_date
    FROM PATENTSVIEW.PATENTSVIEW.PATENT      p
    JOIN PATENTSVIEW.PATENTSVIEW.APPLICATION a
          ON a."patent_id" = p."id"
    WHERE p."country" = 'US'
    GROUP BY p."id",
             p."title",
             p."abstract",
             TRY_TO_DATE(p."date")
),

PAT_FILTERED AS (   /* patents filed 1 Jan 2014 – 1 Feb 2014 in required CPC scopes */
    SELECT DISTINCT pa.*
    FROM PAT_APP                              pa
    JOIN PATENTSVIEW.PATENTSVIEW.CPC_CURRENT  cc
         ON cc."patent_id" = pa.patent_id
    WHERE pa.filing_date BETWEEN '2014-01-01' AND '2014-02-01'
      AND pa.publication_date IS NOT NULL
      AND (
           cc."subsection_id" IN ('C05','C06','C07','C08','C09','C10','C11','C12','C13')
           OR cc."group_id"   IN ('A01G','A01H','A61K','A61P','A61Q',
                                  'B01F','B01J','B81B','B82B','B82Y',
                                  'G01N','G16H')
          )
),

BACKWARD AS (       /* backward citations made before filing date */
    SELECT
        bc."patent_id"                              AS patent_id,
        COUNT(DISTINCT bc."citation_id")            AS backward_citations
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION bc
    JOIN PAT_FILTERED pa
         ON pa.patent_id = bc."patent_id"
    WHERE TRY_TO_DATE(bc."date") IS NOT NULL
      AND TRY_TO_DATE(bc."date") < pa.filing_date
    GROUP BY bc."patent_id"
),

FORWARD AS (        /* forward citations received within 5 yrs of publication */
    SELECT
        fc."citation_id"                            AS patent_id,
        COUNT(DISTINCT fc."patent_id")              AS forward_citations_5y
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION fc
    JOIN PAT_FILTERED pa
         ON pa.patent_id = fc."citation_id"
    WHERE TRY_TO_DATE(fc."date") IS NOT NULL
      AND TRY_TO_DATE(fc."date") >= pa.publication_date
      AND TRY_TO_DATE(fc."date") <= DATEADD(year, 5, pa.publication_date)
    GROUP BY fc."citation_id"
)

SELECT
    pa.patent_id,
    pa."title",
    pa."abstract",
    pa.publication_date,
    COALESCE(b.backward_citations, 0)      AS backward_citations,
    COALESCE(f.forward_citations_5y, 0)    AS forward_citations_first_5yrs
FROM PAT_FILTERED pa
LEFT JOIN BACKWARD b  ON pa.patent_id = b.patent_id
LEFT JOIN FORWARD  f  ON pa.patent_id = f.patent_id
ORDER BY pa.publication_date, pa.patent_id;