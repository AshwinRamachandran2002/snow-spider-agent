SELECT
    p."publication_number"                                                AS "publication_number",
    SUM(
        CASE
            WHEN f.value:"category"::STRING = 'SEA' THEN 1
            ELSE 0
        END
    )                                                                     AS "sea_backward_citations"
FROM PATENTS.PATENTS.PUBLICATIONS AS p
     , LATERAL FLATTEN(
           INPUT  => p."citation",
           OUTER  => TRUE                 -- keep rows with no citations
       ) AS f
WHERE p."grant_date" BETWEEN 20100101 AND 20181231
GROUP BY p."publication_number"
ORDER BY p."publication_number";