SELECT
    p."publication_number",
    SUM(
        CASE 
            WHEN f.value:"category"::string = 'SEA' THEN 1 
            ELSE 0 
        END
    ) AS "sea_backward_citation_count"
FROM PATENTS.PATENTS.PUBLICATIONS AS p
LEFT JOIN LATERAL FLATTEN(
        input => p."citation",
        outer => TRUE          -- keeps rows that have no citation array
) AS f
WHERE p."grant_date" BETWEEN 20100101 AND 20181231   -- granted from 2010‑01‑01 to 2018‑12‑31
GROUP BY p."publication_number"
ORDER BY p."publication_number";