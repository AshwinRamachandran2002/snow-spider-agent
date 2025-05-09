WITH pat_filtered AS (                         -- U.S. patents filed 1 Jan 2014 – 1 Feb 2014
    SELECT
        p."id"                    AS "patent_id",
        p."title",
        p."abstract",
        TRY_TO_DATE(p."date")     AS "pub_date",
        TRY_TO_DATE(a."date")     AS "app_date"
    FROM PATENTSVIEW.PATENTSVIEW.PATENT      p
    JOIN PATENTSVIEW.PATENTSVIEW.APPLICATION a
          ON a."patent_id" = p."id"
    WHERE p."country" = 'US'
      AND TRY_TO_DATE(a."date") >= '2014-01-01'
      AND TRY_TO_DATE(a."date") <  '2014-02-02'
),
pat_cpc AS (                                   -- chemistry / biology / medical CPC only
    SELECT DISTINCT "patent_id"
    FROM PATENTSVIEW.PATENTSVIEW.CPC_CURRENT
    WHERE "subsection_id" IN ('C05','C06','C07','C08','C09',
                              'C10','C11','C12','C13')
       OR "group_id"     IN ('A01G','A01H',
                              'A61K','A61P','A61Q',
                              'B01F','B01J',
                              'B81B',
                              'B82B','B82Y',
                              'G01N','G16H')
),
pat_list AS (                                  -- patents that satisfy both filters
    SELECT pf.*
    FROM pat_filtered pf
    JOIN pat_cpc pc
      ON pf."patent_id" = pc."patent_id"
),
backward AS (                                  -- backward citations before filing date
    SELECT
        uc."patent_id",
        COUNT(*) AS backward_ct
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
    JOIN pat_list pl
          ON pl."patent_id" = uc."patent_id"
    WHERE TRY_TO_DATE(uc."date") IS NOT NULL
      AND TRY_TO_DATE(uc."date") < pl."app_date"
    GROUP BY uc."patent_id"
),
forward AS (                                   -- forward citations within 5 yrs of publication
    SELECT
        uc."citation_id"   AS "patent_id",
        COUNT(*)           AS forward_ct
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
    JOIN pat_list pl
          ON pl."patent_id" = uc."citation_id"
    WHERE TRY_TO_DATE(uc."date") IS NOT NULL
      AND TRY_TO_DATE(uc."date") >  pl."pub_date"
      AND TRY_TO_DATE(uc."date") <= DATEADD(year, 5, pl."pub_date")
    GROUP BY uc."citation_id"
)
SELECT
    pl."patent_id",
    pl."title",
    pl."abstract",
    pl."pub_date"                 AS "publication_date",
    COALESCE(b.backward_ct, 0)    AS "backward_citations",
    COALESCE(f.forward_ct, 0)     AS "forward_citations_5yr"
FROM pat_list pl
LEFT JOIN backward b ON pl."patent_id" = b."patent_id"
LEFT JOIN forward  f ON pl."patent_id" = f."patent_id"
ORDER BY pl."pub_date" DESC NULLS LAST,
         pl."patent_id";