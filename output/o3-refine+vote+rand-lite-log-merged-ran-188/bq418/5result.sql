-- Find the three lowest–level Homo sapiens Reactome pathways (TAS evidence)
-- with the highest χ2 enrichment for experimentally‑supported
-- (median ≤100 nM, low & high ≤100 nM or NULL) Homo sapiens targets of sorafenib.
-- Return the 2×2‑table counts for each of those pathways.

WITH
/* -------------------------------------------------------------------------- */
/* 1.  DrugIDs that correspond to sorafenib (any synonym that contains it)    */
drug_ids AS (
  SELECT DISTINCT `drugID`
  FROM   `isb-cgc-bq.targetome_versioned.drug_synonyms_v1`
  WHERE  LOWER(`synonym`) LIKE '%sorafenib%'
),

/* -------------------------------------------------------------------------- */
/* 2.  Interactions for sorafenib                                             */
sora_int AS (       -- single row per (interactionID,targetID,expID)
  SELECT  DISTINCT i.interactionID,
          i.targetID,
          i.expID,
          i.target_uniprotID AS uniprot_id
  FROM    `isb-cgc-bq.targetome_versioned.interactions_v1` i
  JOIN    drug_ids d                 ON i.drugID = d.drugID
  WHERE   i.targetSpecies = 'Homo sapiens'
),

/* -------------------------------------------------------------------------- */
/* 3.  Keep only experiments that meet potency constraints (≤100 nM)          */
potent_exp AS (
  SELECT  expID
  FROM    `isb-cgc-bq.targetome_versioned.experiments_v1`
  WHERE   exp_assayValueMedian IS NOT NULL
      AND exp_assayValueMedian <= 100
      AND (exp_assayValueLow   IS NULL OR exp_assayValueLow  <= 100)
      AND (exp_assayValueHigh  IS NULL OR exp_assayValueHigh <= 100)
),

/* -------------------------------------------------------------------------- */
/* 4.  Final list of sorafenib targets (UniProt) that have potent evidence    */
sora_targets_uni AS (
  SELECT DISTINCT uniprot_id
  FROM   sora_int
  WHERE  expID IN (SELECT expID FROM potent_exp)
),

/* -------------------------------------------------------------------------- */
/* 5.  Map those UniProts to Reactome physical‐entity stable_ids              */
sora_targets_pe AS (
  SELECT DISTINCT pe.stable_id
  FROM   `isb-cgc-bq.reactome_versioned.physical_entity_v77` pe
  JOIN   sora_targets_uni t  ON pe.uniprot_id = t.uniprot_id
),

/* -------------------------------------------------------------------------- */
/* 6.  Universe of physical entities: any Homo sapiens PE (has UniProt) that  */
/*     is mapped to at least one pathway by TAS evidence                      */
universe_pe AS (
  SELECT DISTINCT pe.stable_id
  FROM   `isb-cgc-bq.reactome_versioned.physical_entity_v77` pe
  JOIN   `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77` pt
             ON pe.stable_id = pt.pe_stable_id
  WHERE  pt.evidence_code = 'TAS'
    AND  pe.uniprot_id IS NOT NULL        -- proxy for Homo sapiens proteins
),

/* -------------------------------------------------------------------------- */
/* 7.  Prepare pathway membership (lowest‑level, Homo sapiens, TAS evidence)  */
pathway_members AS (
  SELECT DISTINCT pt.pathway_stable_id       AS pathway_id,
                  pt.pe_stable_id            AS stable_id
  FROM   `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77` pt
  JOIN   `isb-cgc-bq.reactome_versioned.pathway_v77` p
         ON p.stable_id = pt.pathway_stable_id
  WHERE  pt.evidence_code = 'TAS'
    AND  p.lowest_level = TRUE
    AND  p.species = 'Homo sapiens'
),

/* -------------------------------------------------------------------------- */
/* 8.  Count A (targets in pathway) and C (non‑targets in pathway)            */
counts_in_pathway AS (
  SELECT
       pm.pathway_id,
       COUNTIF(pm.stable_id IN (SELECT * FROM sora_targets_pe))                    AS A_targets_in,
       COUNTIF(pm.stable_id NOT IN (SELECT * FROM sora_targets_pe))                AS C_nontargets_in
  FROM  pathway_members pm
  GROUP BY pm.pathway_id
),

/* -------------------------------------------------------------------------- */
/* 9.  Totals of targets / non‑targets in universe                             */
totals AS (
  SELECT
     (SELECT COUNT(*) FROM sora_targets_pe)                         AS tot_targets,
     (SELECT COUNT(*) FROM universe_pe) -
     (SELECT COUNT(*) FROM sora_targets_pe)                         AS tot_nontargets
),

/* -------------------------------------------------------------------------- */
/* 10.  Assemble 2×2 table and χ2 statistic                                   */
chi2 AS (
  SELECT
      c.pathway_id,
      p.name                                              AS pathway_name,
      A_targets_in                                       AS targets_in,
      (tot.tot_targets     - A_targets_in)               AS targets_out,
      C_nontargets_in                                    AS nontargets_in,
      (tot.tot_nontargets - C_nontargets_in)             AS nontargets_out,
      -- Chi‑squared with Yates correction not requested
      SAFE_DIVIDE( POW( (A_targets_in * (tot.tot_nontargets - C_nontargets_in) -
                         (tot.tot_targets - A_targets_in) * C_nontargets_in ), 2 )
                   * (tot.tot_targets + tot.tot_nontargets) ,
                   (tot.tot_targets) * (tot.tot_nontargets) *
                   (A_targets_in + C_nontargets_in) *
                   ( (tot.tot_targets - A_targets_in) + (tot.tot_nontargets - C_nontargets_in) )
                 )                                       AS chi_squared
  FROM   counts_in_pathway c
  CROSS JOIN totals tot
  JOIN   `isb-cgc-bq.reactome_versioned.pathway_v77` p
         ON p.stable_id = c.pathway_id
)

/* -------------------------------------------------------------------------- */
/* 11.  Return the top‑3 pathways by χ2 statistic                              */
SELECT
    pathway_id,
    pathway_name,
    targets_in,
    targets_out,
    nontargets_in,
    nontargets_out,
    ROUND(chi_squared,4) AS chi_squared
FROM chi2
ORDER BY chi_squared DESC
LIMIT 3;