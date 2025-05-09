SELECT
    pub."publication_number",
    SUM(
        CASE 
            WHEN LOWER(cit.value:"category"::string) = 'sea' THEN 1
            ELSE 0
        END
    ) AS "sea_backward_citation_count"
FROM PATENTS.PATENTS.PUBLICATIONS AS pub
LEFT JOIN LATERAL FLATTEN(
        input  => pub."citation",
        OUTER  => TRUE           -- keep rows even when no citations exist
) cit
WHERE pub."grant_date" BETWEEN 20100101 AND 20181231   -- patents granted 2010-2018
GROUP BY pub."publication_number"
ORDER BY pub."publication_number" NULLS LAST;