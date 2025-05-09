/* Publication-level count of backward citations in the “SEA” category
   for patents granted between 2010-01-01 and 2018-12-31 */

SELECT
    pub."publication_number",
    SUM(
        CASE
            WHEN cit.value:"category"::STRING = 'SEA' THEN 1
            ELSE 0
        END
    ) AS "sea_backward_citations"
FROM PATENTS.PATENTS.PUBLICATIONS AS pub,
     LATERAL FLATTEN(
         INPUT => pub."citation",
         OUTER => TRUE               -- keeps publications without citations
     ) AS cit
WHERE
      pub."grant_date" IS NOT NULL
  AND pub."grant_date" BETWEEN 20100101 AND 20181231
GROUP BY
    pub."publication_number"
ORDER BY
    pub."publication_number" NULLS LAST;