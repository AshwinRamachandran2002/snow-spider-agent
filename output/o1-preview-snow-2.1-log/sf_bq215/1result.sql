WITH patent_citations AS (
  SELECT
    p."publication_number" AS "citing_pub_num",
    c.value:"publication_number"::STRING AS "cited_pub_num"
  FROM
    PATENTS.PATENTS.PUBLICATIONS p,
    LATERAL FLATTEN(input => p."citation") AS c
  WHERE
    p."country_code" = 'US'
    AND p."kind_code" = 'B2'
    AND p."grant_date" BETWEEN 20150101 AND 20181231
),
cited_ipc_codes AS (
  SELECT
    p."publication_number" AS "cited_pub_num",
    SUBSTR(ipc.value:"code"::STRING, 1, 4) AS "ipc_code"
  FROM
    PATENTS.PATENTS.PUBLICATIONS p,
    LATERAL FLATTEN(input => p."ipc") AS ipc
),
citations_with_ipc AS (
  SELECT
    pc."citing_pub_num",
    cic."ipc_code"
  FROM
    patent_citations pc
  LEFT JOIN cited_ipc_codes cic
    ON pc."cited_pub_num" = cic."cited_pub_num"
  WHERE
    cic."ipc_code" IS NOT NULL
),
total_citations AS (
  SELECT
    "citing_pub_num",
    COUNT(*) AS "n_i"
  FROM
    citations_with_ipc
  GROUP BY
    "citing_pub_num"
),
ipc_citation_counts AS (
  SELECT
    "citing_pub_num",
    "ipc_code",
    COUNT(*) AS "n_ik"
  FROM
    citations_with_ipc
  GROUP BY
    "citing_pub_num",
    "ipc_code"
),
originality_components AS (
  SELECT
    icc."citing_pub_num",
    SUM(POWER(icc."n_ik"::FLOAT / tc."n_i"::FLOAT, 2)) AS "sum_sq"
  FROM
    ipc_citation_counts icc
  JOIN total_citations tc
    ON icc."citing_pub_num" = tc."citing_pub_num"
  GROUP BY
    icc."citing_pub_num"
),
originality_scores AS (
  SELECT
    oc."citing_pub_num" AS "publication_number",
    1 - oc."sum_sq" AS "originality_score"
  FROM
    originality_components oc
)
SELECT
  "publication_number"
FROM
  originality_scores
ORDER BY
  "originality_score" DESC NULLS LAST
LIMIT 1;