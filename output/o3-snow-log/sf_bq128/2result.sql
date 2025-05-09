WITH
/* 1. U.S. applications filed between 2014-01-01 and 2014-02-01 */
us_apps AS (
    SELECT DISTINCT "patent_id"
    FROM PATENTSVIEW.PATENTSVIEW.APPLICATION
    WHERE "country" = 'US'
      AND TO_DATE("date") BETWEEN '2014-01-01' AND '2014-02-01'
),

/* 2. Patents whose CPC places them in the requested chemistry/biology/medical domain */
cpc_ok AS (
    SELECT DISTINCT "patent_id"
    FROM PATENTSVIEW.PATENTSVIEW.CPC_CURRENT
    WHERE ( "section_id" = 'C'
            AND "subsection_id" IN ('C05','C06','C07','C08','C09','C10','C11','C12','C13') )
       OR "group_id" IN ('A01G','A01H','A61K','A61P','A61Q',
                         'B01F','B01J',
                         'B81B',
                         'B82B','B82Y',
                         'G01N','G16H')
),

/* 3. Target patents: satisfy both filing-window and CPC requirements */
target AS (
    SELECT DISTINCT
           p."id"        AS "patent_id",
           p."title",
           p."abstract",
           TO_DATE(p."date") AS "publication_date"
    FROM PATENTSVIEW.PATENTSVIEW.PATENT p
         JOIN us_apps ua ON ua."patent_id" = p."id"
         JOIN cpc_ok  co ON co."patent_id" = p."id"
    WHERE p."country" = 'US'
),

/* 4. Backward citations made BEFORE the application filing date */
backward AS (
    SELECT uc."patent_id",
           COUNT(*) AS "backward_cnt"
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
         JOIN PATENTSVIEW.PATENTSVIEW.APPLICATION a
           ON a."patent_id" = uc."patent_id"
          AND a."country"   = 'US'
    WHERE uc."patent_id" IN (SELECT "patent_id" FROM target)
      AND TO_DATE(uc."date") < TO_DATE(a."date")
    GROUP BY uc."patent_id"
),

/* 5. Forward citations that occur WITHIN 5 years after publication */
forward AS (
    SELECT uc."citation_id" AS "patent_id",
           COUNT(*)         AS "forward_cnt"
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
         JOIN PATENTSVIEW.PATENTSVIEW.PATENT   pcurr
           ON pcurr."id" = uc."citation_id"
         JOIN PATENTSVIEW.PATENTSVIEW.PATENT   pcite
           ON pcite."id" = uc."patent_id"
    WHERE uc."citation_id" IN (SELECT "patent_id" FROM target)
      AND TO_DATE(pcite."date") >  TO_DATE(pcurr."date")               /* truly forward   */
      AND TO_DATE(pcite."date") <= DATEADD(year, 5, TO_DATE(pcurr."date")) /* ≤5-yr window */
    GROUP BY uc."citation_id"
)

/* 6. Final assembled result */
SELECT
       t."patent_id",
       t."title",
       t."abstract",
       t."publication_date",
       COALESCE(b."backward_cnt", 0) AS "backward_citations",
       COALESCE(f."forward_cnt",  0) AS "forward_citations_5yr"
FROM target   t
LEFT JOIN backward b ON b."patent_id" = t."patent_id"
LEFT JOIN forward  f ON f."patent_id" = t."patent_id"
ORDER BY t."patent_id";