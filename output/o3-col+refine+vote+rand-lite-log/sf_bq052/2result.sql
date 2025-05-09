WITH tgt AS (   -- target patents with a parsable application date
    SELECT
        a."patent_id",
        TRY_TO_DATE(a."date", 'YYYY-MM-DD') AS "app_date"
    FROM PATENTSVIEW.PATENTSVIEW."APPLICATION" a
    WHERE a."date" IS NOT NULL
),

back AS (        -- patents that CITE the target ≤30 days BEFORE its application
    SELECT
        t."patent_id",
        COUNT(*) AS "backward_1m"
    FROM tgt t
    JOIN PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" uc
         ON uc."citation_id" = t."patent_id"                 -- target is cited
    WHERE TRY_TO_DATE(uc."date", 'YYYY-MM-DD') IS NOT NULL
      AND DATEDIFF('day',
                   TRY_TO_DATE(uc."date", 'YYYY-MM-DD'),
                   t."app_date") BETWEEN 1 AND 30
    GROUP BY t."patent_id"
),

fwd AS (         -- patents that CITE the target ≤30 days AFTER its application
    SELECT
        t."patent_id",
        COUNT(*) AS "forward_1m"
    FROM tgt t
    JOIN PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" uc
         ON uc."patent_id" = t."patent_id"                   -- target is citing
    WHERE TRY_TO_DATE(uc."date", 'YYYY-MM-DD') IS NOT NULL
      AND DATEDIFF('day',
                   t."app_date",
                   TRY_TO_DATE(uc."date", 'YYYY-MM-DD')) BETWEEN 1 AND 30
    GROUP BY t."patent_id"
),

citation_counts AS (  -- combine backward / forward numbers
    SELECT
        COALESCE(b."patent_id", f."patent_id")        AS "patent_id",
        COALESCE(b."backward_1m", 0)                  AS "backward_1m",
        COALESCE(f."forward_1m", 0)                   AS "forward_1m"
    FROM back b
    FULL JOIN fwd f USING ("patent_id")
)

SELECT DISTINCT
       p."id"                           AS "patent_id",
       p."title",
       tgt."app_date"                   AS "application_date",
       cc."backward_1m"                 AS "backward_citations_within_1m",
       cc."forward_1m"                  AS "forward_citations_within_1m",
       p."abstract"
FROM   citation_counts                cc
JOIN   tgt                            ON tgt."patent_id" = cc."patent_id"
JOIN   PATENTSVIEW.PATENTSVIEW."PATENT"        p  ON p."id" = cc."patent_id"
JOIN   PATENTSVIEW.PATENTSVIEW."CPC_CURRENT"   c  ON c."patent_id" = cc."patent_id"
WHERE  (c."subsection_id" = 'C05' OR c."group_id" = 'A01G')      -- desired CPC scopes
  AND  (cc."backward_1m" > 0 OR cc."forward_1m" > 0)             -- at least one 30-day cite
ORDER BY tgt."app_date";