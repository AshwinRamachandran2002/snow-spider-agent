WITH ca_patents AS (
    /* patents that have at least one inventor listed */
    SELECT
        t."publication_number",
        t."publication_date",
        COUNT(f.value) AS "inventor_cnt"
    FROM PATENTS.PATENTS.PUBLICATIONS t,
         LATERAL FLATTEN(input => t."inventor") f
    WHERE t."country_code" = 'CA'
      AND t."publication_date" BETWEEN 19600101 AND 20201231
    GROUP BY t."publication_number", t."publication_date"
),
bucketed AS (
    /* assign each patent to a 5-year bucket starting with 1960-1964 */
    SELECT
        "publication_number",
        "publication_date",
        "inventor_cnt",
        FLOOR((FLOOR("publication_date" / 10000) - 1960) / 5) AS bucket_idx
    FROM ca_patents
)
SELECT
    1960 + bucket_idx * 5  AS "start_year",
    1964 + bucket_idx * 5  AS "end_year",
    COUNT(*)               AS "publication_count",
    ROUND(AVG("inventor_cnt"), 4) AS "avg_inventors_per_patent"
FROM bucketed
GROUP BY bucket_idx
ORDER BY "start_year";