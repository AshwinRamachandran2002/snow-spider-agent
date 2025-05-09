--  TOP-3 lowest-level Reactome pathways (Homo sapiens, TAS evidence)
--  with the highest χ² enrichment for potent sorafenib targets
WITH
/*──────────────────────────────────────────────────────────────────────────────*/
/* 1) Potent sorafenib targets (UniProt IDs)                                   */
potent_targets AS (
  SELECT DISTINCT i.target_uniprotID
  FROM `isb-cgc-bq.targetome_versioned.interactions_v1`  AS i
  JOIN `isb-cgc-bq.targetome_versioned.experiments_v1`   AS e
    ON i.expID = e.expID
  WHERE i.drugID = 157                              -- sorafenib
    AND e.exp_assayValueMedian <= 100
    AND (e.exp_assayValueLow  <= 100 OR e.exp_assayValueLow  IS NULL)
    AND (e.exp_assayValueHigh <= 100 OR e.exp_assayValueHigh IS NULL)
    AND i.target_uniprotID IS NOT NULL
),
/*──────────────────────────────────────────────────────────────────────────────*/
/* 2) Map those UniProt IDs to Reactome physical-entity (PE) stable IDs        */
potent_pe AS (
  SELECT DISTINCT pe.stable_id AS pe_stable_id
  FROM potent_targets AS pt
  JOIN `isb-cgc-bq.reactome_versioned.physical_entity_v77` AS pe
    ON pe.uniprot_id = pt.target_uniprotID
),
/*──────────────────────────────────────────────────────────────────────────────*/
/* 3) Universe = every PE with TAS evidence to a lowest-level human pathway    */
universe_pe AS (
  SELECT DISTINCT pp.pe_stable_id
  FROM `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77` AS pp
  JOIN `isb-cgc-bq.reactome_versioned.pathway_v77`       AS pw
    ON pw.stable_id = pp.pathway_stable_id
  WHERE pp.evidence_code = 'TAS'
    AND pw.lowest_level  = TRUE
    AND pw.species       = 'Homo sapiens'
),
/*──────────────────────────────────────────────────────────────────────────────*/
/* 4) PE ↔ pathway mapping (restricted to TAS, lowest level, human)            */
pathway_pe AS (
  SELECT DISTINCT
    pp.pathway_stable_id,
    pp.pe_stable_id
  FROM `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77` AS pp
  JOIN `isb-cgc-bq.reactome_versioned.pathway_v77`       AS pw
    ON pw.stable_id = pp.pathway_stable_id
  WHERE pp.evidence_code = 'TAS'
    AND pw.lowest_level  = TRUE
    AND pw.species       = 'Homo sapiens'
),
/*──────────────────────────────────────────────────────────────────────────────*/
/* 5) Totals needed for contingency tables                                     */
totals AS (
  SELECT
    (SELECT COUNT(*) FROM potent_pe)       AS n_targets,
    (SELECT COUNT(*) FROM universe_pe)     AS n_universe
),
/*──────────────────────────────────────────────────────────────────────────────*/
/* 6) 2×2 counts for every pathway                                             */
stats AS (
  SELECT
    pw.stable_id                                         AS pathway_id,
    pw.name                                              AS pathway_name,
    COUNT(DISTINCT CASE WHEN pot.pe_stable_id IS NOT NULL THEN ppe.pe_stable_id END) AS a_targets_in,
    t.n_targets -
      COUNT(DISTINCT CASE WHEN pot.pe_stable_id IS NOT NULL THEN ppe.pe_stable_id END)               AS b_targets_out,
    COUNT(DISTINCT CASE WHEN pot.pe_stable_id IS NULL THEN ppe.pe_stable_id END)                     AS c_nontargets_in,
    (t.n_universe - t.n_targets) -
      COUNT(DISTINCT CASE WHEN pot.pe_stable_id IS NULL THEN ppe.pe_stable_id END)                   AS d_nontargets_out
  FROM pathway_pe            AS ppe
  JOIN `isb-cgc-bq.reactome_versioned.pathway_v77` pw
    ON pw.stable_id = ppe.pathway_stable_id
  LEFT JOIN potent_pe        AS pot
    ON pot.pe_stable_id = ppe.pe_stable_id
  CROSS JOIN totals          AS t
  GROUP BY pathway_id, pathway_name, t.n_targets, t.n_universe
),
/*──────────────────────────────────────────────────────────────────────────────*/
/* 7) χ² statistic per pathway                                                 */
chi_sq_calc AS (
  SELECT
    pathway_id,
    pathway_name,
    a_targets_in,
    b_targets_out,
    c_nontargets_in,
    d_nontargets_out,
    -- χ² = N(ad−bc)² / ((a+b)(c+d)(a+c)(b+d))
    ( (a_targets_in + b_targets_out + c_nontargets_in + d_nontargets_out) *
      POW(a_targets_in * d_nontargets_out - b_targets_out * c_nontargets_in, 2) /
      NULLIF( (a_targets_in + b_targets_out) *
              (c_nontargets_in + d_nontargets_out) *
              (a_targets_in + c_nontargets_in) *
              (b_targets_out + d_nontargets_out) , 0) )             AS chi_sq
  FROM stats
)
/*──────────────────────────────────────────────────────────────────────────────*/
/* 8) Return the top-3 pathways                                                */
SELECT
  pathway_id,
  pathway_name,
  a_targets_in      AS targets_in_pathway,
  b_targets_out     AS targets_outside_pathway,
  c_nontargets_in   AS nontargets_in_pathway,
  d_nontargets_out  AS nontargets_outside_pathway,
  chi_sq
FROM chi_sq_calc
ORDER BY chi_sq DESC
LIMIT 3;