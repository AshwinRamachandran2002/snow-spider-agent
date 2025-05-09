SELECT DISTINCT
    p."id",
    p."title",
    a."date" AS "application_date",
    COALESCE(fwd_citations."forward_citation_count", 0) AS "forward_citation_count",
    COALESCE(bwd_citations."backward_citation_count", 0) AS "backward_citation_count",
    REPLACE(b."text", '"', '') AS "summary_text"
FROM
    "PATENTSVIEW"."PATENTSVIEW"."PATENT" p
JOIN
    "PATENTSVIEW"."PATENTSVIEW"."APPLICATION" a ON p."id" = a."patent_id"
JOIN
    "PATENTSVIEW"."PATENTSVIEW"."CPC_CURRENT" c ON p."id" = c."patent_id"
LEFT JOIN
    "PATENTSVIEW"."PATENTSVIEW"."BRF_SUM_TEXT" b ON p."id" = b."patent_id"
LEFT JOIN
    (
        SELECT
            upc."patent_id",
            COUNT(DISTINCT upc."citation_id") AS "backward_citation_count"
        FROM
            "PATENTSVIEW"."PATENTSVIEW"."USPATENTCITATION" upc
        JOIN "PATENTSVIEW"."PATENTSVIEW"."APPLICATION" a_p ON upc."patent_id" = a_p."patent_id"
        JOIN "PATENTSVIEW"."PATENTSVIEW"."APPLICATION" a_c ON upc."citation_id" = a_c."patent_id"
        WHERE
            TRY_TO_DATE(a_p."date", 'YYYY-MM-DD') IS NOT NULL AND
            TRY_TO_DATE(a_c."date", 'YYYY-MM-DD') IS NOT NULL AND
            ABS(DATEDIFF('day', TRY_TO_DATE(a_p."date", 'YYYY-MM-DD'), TRY_TO_DATE(a_c."date", 'YYYY-MM-DD'))) <= 30
        GROUP BY
            upc."patent_id"
    ) bwd_citations ON p."id" = bwd_citations."patent_id"
LEFT JOIN
    (
        SELECT
            upc."citation_id" AS "patent_id",
            COUNT(DISTINCT upc."patent_id") AS "forward_citation_count"
        FROM
            "PATENTSVIEW"."PATENTSVIEW"."USPATENTCITATION" upc
        JOIN "PATENTSVIEW"."PATENTSVIEW"."APPLICATION" a_citing ON upc."patent_id" = a_citing."patent_id"
        JOIN "PATENTSVIEW"."PATENTSVIEW"."APPLICATION" a_cited ON upc."citation_id" = a_cited."patent_id"
        WHERE
            TRY_TO_DATE(a_citing."date", 'YYYY-MM-DD') IS NOT NULL AND
            TRY_TO_DATE(a_cited."date", 'YYYY-MM-DD') IS NOT NULL AND
            ABS(DATEDIFF('day', TRY_TO_DATE(a_citing."date", 'YYYY-MM-DD'), TRY_TO_DATE(a_cited."date", 'YYYY-MM-DD'))) <= 30
        GROUP BY
            upc."citation_id"
    ) fwd_citations ON p."id" = fwd_citations."patent_id"
WHERE
    p."country" = 'US' AND
    (
        c."subsection_id" = 'C05' OR
        c."group_id" = 'A01G'
    ) AND
    (
        COALESCE(fwd_citations."forward_citation_count", 0) >= 1 OR
        COALESCE(bwd_citations."backward_citation_count", 0) >= 1
    )
LIMIT 100;