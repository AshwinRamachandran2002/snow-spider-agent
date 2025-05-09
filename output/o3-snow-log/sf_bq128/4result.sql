WITH app_dates AS (
    SELECT
        "patent_id",
        MIN(TRY_TO_DATE("date")) AS "filing_date"
    FROM PATENTSVIEW.PATENTSVIEW."APPLICATION"
    WHERE TRY_TO_DATE("date") IS NOT NULL
    GROUP BY "patent_id"
),
filtered_patents AS (
    SELECT
        p."id"                    AS "patent_id",
        p."title",
        p."abstract",
        TRY_TO_DATE(p."date")     AS "publication_date",
        a."filing_date"
    FROM PATENTSVIEW.PATENTSVIEW."PATENT" p
    JOIN app_dates a
      ON a."patent_id" = p."id"
    WHERE p."country" = 'US'
      AND a."filing_date" BETWEEN '2014-01-01' AND '2014-02-01'
      AND TRY_TO_DATE(p."date") IS NOT NULL
      AND EXISTS (
            SELECT 1
            FROM PATENTSVIEW.PATENTSVIEW."CPC_CURRENT" c
            WHERE c."patent_id" = p."id"
              AND (
                    (c."section_id" = 'C'
                     AND c."subsection_id" IN ('C05','C06','C07','C08','C09','C10','C11','C12','C13'))
                    OR c."group_id" IN ('A01G','A01H','A61K','A61P','A61Q',
                                        'B01F','B01J','B81B','B82B','B82Y',
                                        'G01N','G16H')
                  )
        )
),
backward_citations AS (
    SELECT
        f."patent_id",
        COUNT(DISTINCT upc."citation_id") AS "backward_count"
    FROM filtered_patents f
    LEFT JOIN PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" upc
           ON upc."patent_id" = f."patent_id"
    LEFT JOIN PATENTSVIEW.PATENTSVIEW."PATENT" cited
           ON cited."id" = upc."citation_id"
    WHERE TRY_TO_DATE(cited."date") IS NOT NULL
      AND TRY_TO_DATE(cited."date") < f."filing_date"
    GROUP BY f."patent_id"
),
forward_citations AS (
    SELECT
        f."patent_id",
        COUNT(DISTINCT upc."patent_id") AS "forward_5yr_count"
    FROM filtered_patents f
    LEFT JOIN PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" upc
           ON upc."citation_id" = f."patent_id"
    LEFT JOIN PATENTSVIEW.PATENTSVIEW."PATENT" citing
           ON citing."id" = upc."patent_id"
    WHERE TRY_TO_DATE(citing."date") IS NOT NULL
      AND TRY_TO_DATE(citing."date") >  f."publication_date"
      AND TRY_TO_DATE(citing."date") <= DATEADD(year, 5, f."publication_date")
    GROUP BY f."patent_id"
)
SELECT
    f."patent_id",
    f."title",
    f."abstract",
    f."publication_date",
    COALESCE(b."backward_count", 0)     AS "backward_citations",
    COALESCE(fc."forward_5yr_count", 0) AS "forward_citations_5yr"
FROM filtered_patents f
LEFT JOIN backward_citations b ON b."patent_id" = f."patent_id"
LEFT JOIN forward_citations fc ON fc."patent_id" = f."patent_id"
ORDER BY f."publication_date" NULLS LAST;