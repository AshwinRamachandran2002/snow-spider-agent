SELECT
    p."publication_number",
    SUM(
        IFF(UPPER(f.value:"category"::STRING) = 'SEA', 1, 0)
    ) AS "sea_backward_citation_count"
FROM PATENTS.PATENTS.PUBLICATIONS AS p,
     LATERAL FLATTEN( INPUT => p."citation", OUTER => TRUE ) AS f
WHERE p."grant_date" BETWEEN 20100101 AND 20181231
GROUP BY p."publication_number"
ORDER BY p."publication_number";