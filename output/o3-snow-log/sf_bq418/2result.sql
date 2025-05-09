/* -----------------------------------------------
   Top three lowest-level Reactome pathways whose 
   TAS-supported members are most enriched for 
   potent Homo-sapiens Sorafenib targets
-------------------------------------------------*/
WITH  /* 1. Potent H. sapiens Sorafenib targets (≤100 nM) */
soraf_targets AS (
    SELECT DISTINCT i."target_uniprotID"
    FROM TARGETOME_REACTOME.TARGETOME_VERSIONED.INTERACTIONS_V1  i
    JOIN TARGETOME_REACTOME.TARGETOME_VERSIONED.EXPERIMENTS_V1   e
           ON i."expID" = e."expID"
    WHERE i."drugID"                = 157            -- Sorafenib Tosylate
      AND i."targetSpecies"         = 'Homo sapiens'
      AND COALESCE(e."exp_assayValueMedian",1000) <= 100
      AND (e."exp_assayValueLow"  <= 100 OR e."exp_assayValueLow"  IS NULL)
      AND (e."exp_assayValueHigh" <= 100 OR e."exp_assayValueHigh" IS NULL)
),
/* 2. Corresponding Reactome physical entities (PEs) */
soraf_pes AS (
    SELECT DISTINCT p."stable_id"  AS "pe_id"
    FROM TARGETOME_REACTOME.REACTOME_VERSIONED.PHYSICAL_ENTITY_V77 p
    JOIN soraf_targets st
      ON p."uniprot_id" = st."target_uniprotID"
),
/* 3. All TAS PE-to-pathway links */
tas_links AS (
    SELECT  "pe_stable_id" AS "pe_id",
            "pathway_stable_id" AS "pw_id"
    FROM TARGETOME_REACTOME.REACTOME_VERSIONED.PE_TO_PATHWAY_V77
    WHERE "evidence_code" = 'TAS'
),
/* 4. Lowest-level pathways that contain ≥1 Sorafenib PE */
soraf_low_pw AS (
    SELECT DISTINCT tl."pw_id"
    FROM   tas_links                     tl
    JOIN   soraf_pes                     sp  ON tl."pe_id" = sp."pe_id"
    JOIN   TARGETOME_REACTOME.REACTOME_VERSIONED.PATHWAY_V77 pw
           ON tl."pw_id" = pw."stable_id"
    WHERE  pw."lowest_level" = TRUE
),
/* 5. Universe = every TAS PE–pathway pair within those pathways */
universe AS (
    SELECT DISTINCT tl."pe_id", tl."pw_id"
    FROM   tas_links tl
    WHERE  tl."pw_id" IN (SELECT "pw_id" FROM soraf_low_pw)
),
/* 6. Contingency-table counts for each pathway */
counts AS (
    SELECT
        u."pw_id"                                               AS "pathway_id",
        /* a: Sorafenib targets inside the pathway */
        COUNT(DISTINCT CASE WHEN u."pe_id" IN (SELECT "pe_id" FROM soraf_pes)
                            THEN u."pe_id" END)                 AS a_targets_in,
        /* b: Sorafenib targets outside the pathway */
        (SELECT COUNT(DISTINCT "pe_id") FROM soraf_pes)
          - COUNT(DISTINCT CASE WHEN u."pe_id" IN (SELECT "pe_id" FROM soraf_pes)
                                THEN u."pe_id" END)             AS b_targets_out,
        /* c: Non-targets inside the pathway */
        COUNT(DISTINCT CASE WHEN u."pe_id" NOT IN (SELECT "pe_id" FROM soraf_pes)
                            THEN u."pe_id" END)                 AS c_nontargets_in,
        /* d: Non-targets outside the pathway */
        (SELECT COUNT(DISTINCT "pe_id") FROM universe)
          - COUNT(DISTINCT u."pe_id")
          - ((SELECT COUNT(DISTINCT "pe_id") FROM soraf_pes)
             - COUNT(DISTINCT CASE WHEN u."pe_id" IN (SELECT "pe_id" FROM soraf_pes)
                                   THEN u."pe_id" END))         AS d_nontargets_out
    FROM universe u
    GROUP BY u."pw_id"
),
/* 7. χ² statistic (1 × 1 with Yates’ continuity not applied) */
stats AS (
    SELECT
        c."pathway_id",
        c.a_targets_in,
        c.b_targets_out,
        c.c_nontargets_in,
        c.d_nontargets_out,
        /* χ² = ( (ad - bc)² N ) / ((a+b)(c+d)(a+c)(b+d)) */
        ( POWER( (c.a_targets_in * c.d_nontargets_out
                  - c.b_targets_out * c.c_nontargets_in), 2 )
          *
          (c.a_targets_in + c.b_targets_out
           + c.c_nontargets_in + c.d_nontargets_out)
        )
        / NULLIF( (c.a_targets_in + c.b_targets_out)
                  * (c.c_nontargets_in + c.d_nontargets_out)
                  * (c.a_targets_in + c.c_nontargets_in)
                  * (c.b_targets_out + c.d_nontargets_out), 0)
        AS chi_squared
    FROM counts c
)
/* 8. Return the top-three pathways by χ² */
SELECT
       st."pathway_id"                                AS "reactome_pathway_id",
       pw."name"                                      AS "pathway_name",
       st.a_targets_in,
       st.b_targets_out,
       st.c_nontargets_in,
       st.d_nontargets_out,
       st.chi_squared
FROM   stats st
JOIN   TARGETOME_REACTOME.REACTOME_VERSIONED.PATHWAY_V77 pw
       ON st."pathway_id" = pw."stable_id"
ORDER BY st.chi_squared DESC NULLS LAST
LIMIT 3;