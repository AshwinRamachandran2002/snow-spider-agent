WITH US_PATENTS AS (       ----------------------------------------------------
/* 1. U.S. patents published between 2014-01-01 and 2014-02-01                */
    SELECT
        P."id"                       AS patent_id ,
        P."title"                    ,
        P."abstract"                 ,
        TRY_TO_DATE(P."date")        AS pub_date
    FROM PATENTSVIEW.PATENTSVIEW.PATENT P
    WHERE P."country" = 'US'
      AND TRY_TO_DATE(P."date") BETWEEN '2014-01-01' AND '2014-02-01'
),
CPC_FILTER AS (            ----------------------------------------------------
/* 2.  Chemistry / biology / medical-related CPC codes                        */
    SELECT DISTINCT C."patent_id"
    FROM PATENTSVIEW.PATENTSVIEW.CPC_CURRENT C
    WHERE C."subsection_id" IN ('C05','C06','C07','C08','C09',
                                'C10','C11','C12','C13')
       OR C."group_id"      IN ('A01G','A01H','A61K','A61P','A61Q',
                                'B01F','B01J','B81B','B82B','B82Y',
                                'G01N','G16H')
),
BASE AS (                 ----------------------------------------------------
/* 3. Earliest filing date for each patent                                    */
    SELECT
        U.patent_id,
        U."title",
        U."abstract",
        U.pub_date,
        MIN(TRY_TO_DATE(A."date")) AS filing_date
    FROM US_PATENTS U
    JOIN CPC_FILTER CF                   ON CF."patent_id" = U.patent_id
    LEFT JOIN PATENTSVIEW.PATENTSVIEW.APPLICATION A
                                         ON A."patent_id" = U.patent_id
    GROUP BY U.patent_id, U."title", U."abstract", U.pub_date
),
BACKWARD AS (             ----------------------------------------------------
/* 4. Backward citations (before filing date)                                */
    SELECT
        B.patent_id,
        COUNT(*) AS backward_ct
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION C
    JOIN BASE B  ON B.patent_id = C."patent_id"
    WHERE B.filing_date IS NOT NULL
      AND TRY_TO_DATE(C."date") IS NOT NULL
      AND TRY_TO_DATE(C."date") <  B.filing_date
    GROUP BY B.patent_id
),
FORWARD AS (              ----------------------------------------------------
/* 5. Forward citations within 5 years after publication                      */
    SELECT
        B.patent_id,
        COUNT(*) AS forward_ct
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION C
    JOIN BASE B  ON B.patent_id = C."citation_id"
    WHERE B.pub_date IS NOT NULL
      AND TRY_TO_DATE(C."date") BETWEEN B.pub_date
                                    AND DATEADD(year, 5, B.pub_date)
    GROUP BY B.patent_id
)
SELECT                     ----------------------------------------------------
    B.patent_id,
    B."title",
    B."abstract",
    B.pub_date                              AS publication_date,
    COALESCE(BW.backward_ct, 0)             AS backward_citations,
    COALESCE(FW.forward_ct , 0)             AS forward_citations_5yrs
FROM BASE B
LEFT JOIN BACKWARD BW ON BW.patent_id = B.patent_id
LEFT JOIN FORWARD  FW ON FW.patent_id = B.patent_id
ORDER BY B.pub_date, B.patent_id;