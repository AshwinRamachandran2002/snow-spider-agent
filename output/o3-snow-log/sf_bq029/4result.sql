WITH ca_pubs AS (
    /* Canadian patent publications that have at least one inventor listed
       and a publication year between 1960 and 2020 */
    SELECT
        "publication_number",
        "publication_date",
        ARRAY_SIZE("inventor")            AS inventor_cnt
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'CA'
      AND "publication_date" IS NOT NULL
      AND "inventor" IS NOT NULL
      AND ARRAY_SIZE("inventor") > 0
      AND CAST("publication_date" / 10000 AS INT) BETWEEN 1960 AND 2020
), bucketed AS (
    /* Assign each publication to a 5-year bucket starting with 1960-1964,
       1965-1969, …, 2020-2024 (the last bucket will only contain 2020) */
    SELECT
        "publication_number",
        inventor_cnt,
        FLOOR( (CAST("publication_date" / 10000 AS INT) - 1960) / 5 ) AS bucket_idx
    FROM ca_pubs
)
SELECT
    /* Build a readable period label, e.g. 1960-1964 */
    CONCAT(
        TO_CHAR(1960 + bucket_idx * 5), '-',
        TO_CHAR(1960 + bucket_idx * 5 + 4)
    )                                               AS "period",
    COUNT(DISTINCT "publication_number")            AS "total_publications",
    ROUND(AVG(inventor_cnt), 4)                     AS "avg_inventors_per_patent"
FROM bucketed
GROUP BY bucket_idx
ORDER BY bucket_idx;