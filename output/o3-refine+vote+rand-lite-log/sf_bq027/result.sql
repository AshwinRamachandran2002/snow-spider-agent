SELECT
    p."publication_number",
    SUM(
        CASE 
            WHEN c.value:"category"::STRING = 'SEA' THEN 1     -- count only SEA‑category citations
            ELSE 0
        END
    ) AS "sea_backward_citations"
FROM PATENTS.PATENTS.PUBLICATIONS  AS p
     , LATERAL FLATTEN(
           INPUT => p."citation",
           OUTER => TRUE          -- guarantees a row even when there are no citations
       )                         AS c
WHERE p."grant_date" BETWEEN 20100101 AND 20181231   -- patents granted 2010‑2018
GROUP BY p."publication_number"
ORDER BY p."publication_number";