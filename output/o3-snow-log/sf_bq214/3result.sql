/*----------------------------------------------------------------------------
  Objective
    1.  Find the US-B2 utility patent (grant 2010-2014) with the most forward
        citations whose citing patents were filed within 30 days of its own
        filing date.
    2.  From patents filed in the same year as that focal patent, pick the
        one whose embedding has the highest dot-product similarity with the
        focal patent.
----------------------------------------------------------------------------*/

WITH /*---------------------------------------------------------*/
focal AS (          /* 1. candidate focal patents               */
    SELECT  p."publication_number",
            p."filing_date"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    WHERE   p."country_code" = 'US'
      AND   p."kind_code"    = 'B2'
      AND   p."grant_date" BETWEEN 20100101 AND 20141231
      AND   p."filing_date"  > 0
),
/* 2. citing → cited pairs with citing filing-date --------------*/
cit AS (
    SELECT  f_cit.value:"publication_number"::STRING AS cited_pub,
            p_cit."publication_number"               AS citing_pub,
            p_cit."filing_date"                      AS citing_filing
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p_cit,
            LATERAL FLATTEN(INPUT => p_cit."citation") f_cit
    WHERE   f_cit.value:"publication_number" IS NOT NULL
),
/* 3. forward-citation counts (≤30 days) ------------------------*/
fc_counts AS (
    SELECT  f."publication_number",
            COUNT(*) AS fc_within_30d
    FROM    focal f
    JOIN    cit   c
          ON c.cited_pub = f."publication_number"
         AND c.citing_filing BETWEEN f."filing_date"
                                AND f."filing_date" + 30
    GROUP BY f."publication_number"
),
/* 4. choose top focal patent -----------------------------------*/
top_focal AS (
    SELECT  f."publication_number",
            f."filing_date",
            fc.fc_within_30d
    FROM    focal f
    JOIN    fc_counts fc USING ("publication_number")
    ORDER BY fc.fc_within_30d DESC NULLS LAST
    LIMIT   1
),
/* 5. focal patent embedding ------------------------------------*/
focal_emb AS (
    SELECT  tf.*,
            e."embedding_v1" AS emb_vec
    FROM    top_focal tf
    JOIN    PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB e
          ON e."publication_number" = tf."publication_number"
),
/* 6. same-year candidate patents (any kind) --------------------*/
same_year AS (
    SELECT  p."publication_number",
            p."filing_date",
            e."embedding_v1" AS emb_vec
    FROM    focal_emb fe,
            PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN    PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB  e
          ON e."publication_number" = p."publication_number"
    WHERE   FLOOR(p."filing_date"/10000) = FLOOR(fe."filing_date"/10000)
      AND   p."publication_number" <> fe."publication_number"
),
/* 7. dot-product similarity ------------------------------------*/
similarity AS (
    SELECT  sy."publication_number"                       AS similar_pub,
            SUM(vec_f.value::FLOAT * vec_s.value::FLOAT)  AS sim_score
    FROM    focal_emb fe,
            LATERAL FLATTEN(INPUT => fe.emb_vec)           vec_f,
            same_year sy,
            LATERAL FLATTEN(INPUT => sy.emb_vec)           vec_s
    WHERE   vec_f.index = vec_s.index
    GROUP BY sy."publication_number"
),
/* 8. most-similar patent --------------------------------------*/
most_similar AS (
    SELECT *
    FROM   similarity
    ORDER  BY sim_score DESC NULLS LAST
    LIMIT  1
)
/*-------------------------  Final result  ----------------------*/
SELECT fe."publication_number"  AS focal_publication,
       fe."filing_date"         AS focal_filing_date,
       fe.fc_within_30d         AS forward_cites_within_30d,
       ms.similar_pub           AS most_similar_publication,
       ms.sim_score             AS similarity_dot_product
FROM   focal_emb  fe
CROSS  JOIN most_similar ms;