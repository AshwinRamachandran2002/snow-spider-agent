WITH focal_candidates AS (   -- U.S. utility patents (kind “B2”) granted 2010‑2014
    SELECT *
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "country_code"      = 'US'
      AND "kind_code"         = 'B2'
      AND "application_kind"  = 'A'          -- utility
      AND "grant_date" BETWEEN 20100101 AND 20141231
),
forward_cite_counts AS (     -- forward citations arriving ≤ 31 days after the focal filing date
    SELECT
        focal."publication_number"                     AS "focal_pub",
        COUNT(DISTINCT citing."publication_number")    AS "fw_cites_1m"
    FROM focal_candidates  focal
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  citing
         ON citing."filing_date" BETWEEN focal."filing_date" AND focal."filing_date" + 31
    CROSS JOIN LATERAL FLATTEN(INPUT => citing."citation") cite
    WHERE CAST(cite.value:"publication_number" AS STRING) = focal."publication_number"
    GROUP BY focal."publication_number"
),
top_focal AS (               -- patent with the most such forward citations
    SELECT "focal_pub", "fw_cites_1m"
    FROM forward_cite_counts
    ORDER BY "fw_cites_1m" DESC NULLS LAST, "focal_pub"
    LIMIT 1
),
focal_info AS (              -- keep its filing year for similarity search
    SELECT p."publication_number",
           p."filing_date",
           FLOOR(p."filing_date" / 10000) AS "filing_year"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN top_focal t ON t."focal_pub" = p."publication_number"
),
focal_emb AS (                -- embedding of the focal patent
    SELECT a."publication_number", a."embedding_v1"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB a
    JOIN focal_info f ON f."publication_number" = a."publication_number"
),
candidate_same_year AS (      -- embeddings of every other patent filed in the same year
    SELECT a."publication_number", a."embedding_v1"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB a
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
          ON p."publication_number" = a."publication_number"
    JOIN focal_info fi
          ON FLOOR(p."filing_date" / 10000) = fi."filing_year"
    WHERE a."publication_number" <> fi."publication_number"
),
similarity_calc AS (          -- dot‑product similarity between embeddings
    SELECT
        c."publication_number"                           AS "candidate_pub",
        SUM(fe.value::float * ce.value::float)           AS "dot_product"
    FROM focal_emb f
    CROSS JOIN LATERAL FLATTEN(INPUT => f."embedding_v1") fe
    JOIN candidate_same_year  c  ON TRUE
    CROSS JOIN LATERAL FLATTEN(INPUT => c."embedding_v1") ce
    WHERE fe.index = ce.index
    GROUP BY c."publication_number"
),
top_similar AS (              -- most similar patent (largest dot product)
    SELECT "candidate_pub" AS "similar_pub", "dot_product"
    FROM similarity_calc
    ORDER BY "dot_product" DESC NULLS LAST, "similar_pub"
    LIMIT 1
)
SELECT
    fi."publication_number"            AS "focal_publication_number",
    tf."fw_cites_1m"                   AS "forward_citations_within_1_month",
    ts."similar_pub"                   AS "most_similar_publication_number",
    ts."dot_product"                   AS "similarity_score"
FROM focal_info   fi
JOIN top_focal    tf ON fi."publication_number" = tf."focal_pub"
JOIN top_similar  ts;