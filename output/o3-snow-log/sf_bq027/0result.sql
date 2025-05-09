SELECT
    p."publication_number",
    SUM(
        CASE
            WHEN c.value:"category"::string = 'SEA' THEN 1
            ELSE 0
        END
    ) AS "sea_backward_citation_count"
FROM PATENTS.PATENTS.PUBLICATIONS AS p,
     LATERAL FLATTEN(
         input => p."citation",
         outer => TRUE
     ) AS c
WHERE p."grant_date" BETWEEN 20100101 AND 20181231
GROUP BY p."publication_number"
ORDER BY "sea_backward_citation_count" DESC NULLS LAST;