/* 1) collect all SEA-category backward citations in the data set
   2) count how many of those cite each patent that was granted 2010-2018    */
WITH sea_backward_citations AS (         -- every SEA backward citation
    SELECT
        ct.value:"publication_number"::string AS "cited_pub_nr"
    FROM PATENTS.PATENTS.PUBLICATIONS  AS citing ,
         LATERAL FLATTEN ( INPUT => citing."citation" ) AS ct
    WHERE  UPPER(ct.value:"category"::string) = 'SEA'                      -- SEA category
       AND (  UPPER(ct.value:"type"::string) = 'BACKWARD'                  -- backward
              OR ct.value:"type" IS NULL )
)
SELECT
       tgt."publication_number",
       COUNT(sea."cited_pub_nr") AS "sea_backward_citation_count"
FROM   PATENTS.PATENTS.PUBLICATIONS AS tgt
       LEFT JOIN sea_backward_citations AS sea
              ON sea."cited_pub_nr" = tgt."publication_number"
WHERE  tgt."grant_date" BETWEEN 20100101 AND 20181231                      -- granted 2010-2018
GROUP BY
       tgt."publication_number"
ORDER BY
       tgt."publication_number";