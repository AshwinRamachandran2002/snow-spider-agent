WITH candidate AS (   -- U.S. utility patents granted 2010‑2014 with kind‑code B2
    SELECT
        "publication_number",
        "filing_date"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "country_code"   = 'US'
      AND "kind_code"      = 'B2'
      AND "application_kind" = 'A'      -- utility / “normal” patent
      AND "grant_date" BETWEEN 20100101 AND 20141231
),

/* forward citations that arrive ≤ 31 days after the focal patent’s filing date */
forward_citation_events AS (
    SELECT
        cand."publication_number"                       AS pub,
        fc.value:"publication_number"::string           AS citing_pub
    FROM candidate                       cand
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB  ab
         ON ab."publication_number" = cand."publication_number"
    ,   LATERAL FLATTEN(input => ab."cited_by")  fc
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS    cit
         ON cit."publication_number" = fc.value:"publication_number"::string
    WHERE cit."filing_date"
          BETWEEN cand."filing_date" AND cand."filing_date" + 31     -- ≤ 1 month
),

/* count of such early forward citations */
aggregated AS (
    SELECT
        pub,
        COUNT(DISTINCT citing_pub) AS citation_count
    FROM forward_citation_events
    GROUP BY pub
),

/* patent with the largest number of early forward citations */
top_patent AS (
    SELECT
        pub,
        citation_count
    FROM aggregated
    ORDER BY citation_count DESC NULLS LAST, pub ASC
    LIMIT 1
),

/* most‑similar patent from the same filing year (any country / kind) */
similar_patent AS (
    SELECT
        sim.value:"publication_number"::string AS similar_pub
    FROM top_patent tp
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB  ab
         ON ab."publication_number" = tp.pub
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS base
         ON base."publication_number" = tp.pub
    ,   LATERAL FLATTEN(input => ab."similar")  sim
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS sim_pub
         ON sim_pub."publication_number" = sim.value:"publication_number"::string
    WHERE FLOOR(sim_pub."filing_date" / 10000) = FLOOR(base."filing_date" / 10000)   -- same filing year
    ORDER BY sim.index ASC                      -- first entry is most similar
    LIMIT 1
)

SELECT
    tp.pub              AS "FOCAL_PUBLICATION_NUMBER",
    tp.citation_count   AS "FORWARD_CITATIONS_WITHIN_MONTH",
    sp.similar_pub      AS "MOST_SIMILAR_PUBLICATION_SAME_YEAR"
FROM top_patent tp
LEFT JOIN similar_patent sp ON 1=1;