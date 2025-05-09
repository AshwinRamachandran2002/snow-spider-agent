WITH core AS (   -- patents in CPC subsection C05 or group A01G + earliest app date
    SELECT
        p."id"                       AS "patent_id",
        p."title",
        MIN(TRY_TO_DATE(a."date"))   AS "application_date",
        p."abstract"
    FROM PATENTSVIEW.PATENTSVIEW."PATENT"       p
    JOIN PATENTSVIEW.PATENTSVIEW."APPLICATION"  a  ON a."patent_id" = p."id"
    JOIN PATENTSVIEW.PATENTSVIEW."CPC_CURRENT"  cc ON cc."patent_id" = p."id"
    WHERE cc."subsection_id" = 'C05'
       OR cc."group_id"      = 'A01G'
    GROUP BY p."id", p."title", p."abstract"
),
backward AS (    -- cites made BY the patent ≤ 1 month before its application date
    SELECT
        c."patent_id",
        COUNT(DISTINCT c."citation_id") AS "backward_1m"
    FROM PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" c
    JOIN core ON core."patent_id" = c."patent_id"
    WHERE TRY_TO_DATE(c."date") BETWEEN DATEADD('day', -31, core."application_date")
                                    AND                       core."application_date"
    GROUP BY c."patent_id"
),
forward AS (     -- cites RECEIVED by the patent ≤ 1 month after its application date
    SELECT
        c."citation_id"               AS "patent_id",
        COUNT(DISTINCT c."patent_id") AS "forward_1m"
    FROM PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" c
    JOIN core ON core."patent_id" = c."citation_id"
    WHERE TRY_TO_DATE(c."date") BETWEEN core."application_date"
                                    AND DATEADD('day', 31, core."application_date")
    GROUP BY c."citation_id"
)
SELECT
    core."patent_id",
    core."title",
    core."application_date",
    COALESCE(b."backward_1m", 0) AS "backward_citations_1m_before_app",
    COALESCE(f."forward_1m", 0)  AS "forward_citations_1m_after_app",
    core."abstract"
FROM core
LEFT JOIN backward b ON b."patent_id" = core."patent_id"
LEFT JOIN forward  f ON f."patent_id" = core."patent_id"
WHERE COALESCE(b."backward_1m", 0) > 0
   OR COALESCE(f."forward_1m", 0) > 0
ORDER BY core."application_date" ASC, core."patent_id";