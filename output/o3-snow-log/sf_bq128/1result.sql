WITH target_patents AS (   /* U.S. patents filed 1-Jan-2014 through 1-Feb-2014 */
    SELECT
        p."id"                       AS patent_id,
        p."title"                    AS title,
        p."abstract"                 AS abstract,
        TRY_TO_DATE(p."date")        AS publication_date,
        TRY_TO_DATE(a."date")        AS filing_date
    FROM PATENTSVIEW.PATENTSVIEW.PATENT      p
    JOIN PATENTSVIEW.PATENTSVIEW.APPLICATION a
          ON a."patent_id" = p."id"
    WHERE p."country" = 'US'
      AND TRY_TO_DATE(a."date") BETWEEN '2014-01-01' AND '2014-02-01'
      AND TRY_TO_DATE(a."date") IS NOT NULL
      AND TRY_TO_DATE(p."date") IS NOT NULL
),

/* backward citations made on or before the citing patent’s filing date */
backward_ct AS (
    SELECT
        bc."patent_id"               AS patent_id,
        COUNT(*)                     AS backward_cnt
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION bc
    JOIN PATENTSVIEW.PATENTSVIEW.APPLICATION      app
          ON app."patent_id" = bc."patent_id"
    WHERE TRY_TO_DATE(bc."date") IS NOT NULL
      AND TRY_TO_DATE(app."date") IS NOT NULL
      AND TRY_TO_DATE(bc."date") <= TRY_TO_DATE(app."date")
    GROUP BY bc."patent_id"
),

/* forward citations that occur within 5 years after the cited patent’s publication */
forward_ct AS (
    SELECT
        fc."citation_id"             AS patent_id,
        COUNT(*)                     AS forward_cnt
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION fc
    JOIN PATENTSVIEW.PATENTSVIEW.PATENT citing_pat
          ON citing_pat."id" = fc."patent_id"
    JOIN PATENTSVIEW.PATENTSVIEW.PATENT cited_pat
          ON cited_pat."id" = fc."citation_id"
    WHERE TRY_TO_DATE(citing_pat."date") IS NOT NULL
      AND TRY_TO_DATE(cited_pat."date")  IS NOT NULL
      AND TRY_TO_DATE(citing_pat."date") BETWEEN
              TRY_TO_DATE(cited_pat."date")              -- on/after publication
          AND DATEADD(year, 5, TRY_TO_DATE(cited_pat."date"))  -- within 5 years
    GROUP BY fc."citation_id"
)

SELECT
    tp.patent_id,
    tp.title,
    tp.abstract,
    tp.publication_date,
    COALESCE(bc.backward_cnt, 0) AS backward_citations,
    COALESCE(fc.forward_cnt , 0) AS forward_citations_5y
FROM target_patents tp
LEFT JOIN backward_ct bc ON bc.patent_id = tp.patent_id
LEFT JOIN forward_ct  fc ON fc.patent_id = tp.patent_id
ORDER BY tp.publication_date NULLS LAST,
         tp.patent_id;