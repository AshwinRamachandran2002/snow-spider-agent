WITH target AS (
    /* focal patent: vector + filing year */
    SELECT
        a."embedding_v1"                       AS "t_vec",
        CAST(FLOOR(p."filing_date"/10000) AS INT) AS "filing_year"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS   p
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB    a
          ON p."publication_number" = a."publication_number"
    WHERE p."publication_number" = 'US-9741766-B2'
),
same_year AS (
    /* all other patents filed in the same year and with embeddings */
    SELECT
        p."publication_number",
        a."embedding_v1" AS "s_vec"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS   p
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB    a
          ON p."publication_number" = a."publication_number"
    JOIN target t
          ON CAST(FLOOR(p."filing_date"/10000) AS INT) = t."filing_year"
    WHERE p."publication_number" <> 'US-9741766-B2'
)
SELECT
    sy."publication_number"
FROM same_year sy,
     target,
     LATERAL FLATTEN(input => target."t_vec") t_f,
     LATERAL FLATTEN(input => sy."s_vec")     s_f
WHERE t_f.index = s_f.index
GROUP BY sy."publication_number"
ORDER BY SUM(t_f.value::FLOAT * s_f.value::FLOAT) DESC NULLS LAST
LIMIT 5;