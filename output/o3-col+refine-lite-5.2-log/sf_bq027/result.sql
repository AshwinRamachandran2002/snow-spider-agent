SELECT 
    t."publication_number",
    COUNT(*) AS "sea_backward_citation_count"
FROM PATENTS.PATENTS.PUBLICATIONS AS t
CROSS JOIN LATERAL FLATTEN(
         input => t."citation"
     ) AS f
WHERE t."grant_date" BETWEEN 20100101 AND 20181231            -- grants from 2010‑2018
  AND f.value::VARIANT:"category"::STRING ILIKE '%SEA%'       -- only SEA‑category backward citations
GROUP BY t."publication_number"
ORDER BY "sea_backward_citation_count" DESC NULLS LAST,
         t."publication_number" ASC;