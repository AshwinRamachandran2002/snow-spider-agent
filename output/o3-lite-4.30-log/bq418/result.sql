WITH
/* 1. Canonical Targetome drugID(s) for sorafenib */
soraf_drug AS (
  SELECT DISTINCT `drugID`
  FROM `isb-cgc-bq.targetome_versioned.drug_synonyms_v1`
  WHERE LOWER(`synonym`) = 'sorafenib'
),

/* 2. UniProt IDs of Homo‑sapiens sorafenib targets with potency ≤ 100 nM */
soraf_targets AS (
  SELECT DISTINCT i.`target_uniprotID` AS uniprot_id
  FROM `isb-cgc-bq.targetome_versioned.interactions_v1`  i
  JOIN soraf_drug                                         sd ON i.`drugID` = sd.`drugID`
  JOIN `isb-cgc-bq.targetome_versioned.experiments_v1`   e  ON i.`expID`  = e.`expID`
  WHERE i.`targetSpecies`        = 'Homo sapiens'
    AND e.`exp_assayUnits`       = 'nM'
    AND e.`exp_assayValueMedian` <= 100
    AND (e.`exp_assayValueLow`   <= 100 OR e.`exp_assayValueLow`  IS NULL)
    AND (e.`exp_assayValueHigh`  <= 100 OR e.`exp_assayValueHigh` IS NULL)
),

/* 3. Universe of all human proteins represented in Reactome */
all_uniprots AS (
  SELECT DISTINCT `uniprot_id`
  FROM `isb-cgc-bq.reactome_versioned.physical_entity_v77`
  WHERE `uniprot_id` IS NOT NULL
),

/* 4. Lowest‑level Human pathways (TAS evidence) with member UniProt IDs */
pathway_members AS (
  SELECT DISTINCT ptp.`pathway_stable_id` AS pathway_id,
                  pe.`uniprot_id`
  FROM `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77`   ptp
  JOIN `isb-cgc-bq.reactome_versioned.physical_entity_v77` pe
       ON ptp.`pe_stable_id` = pe.`stable_id`
  JOIN `isb-cgc-bq.reactome_versioned.pathway_v77`         pw
       ON ptp.`pathway_stable_id` = pw.`stable_id`
  WHERE ptp.`evidence_code` = 'TAS'
    AND pw.`lowest_level`   = TRUE
    AND pw.`species`        = 'Homo sapiens'
    AND pe.`uniprot_id` IS NOT NULL
),

/* 5. Counts of targets / non‑targets inside each pathway */
counts AS (
  SELECT
    pm.`pathway_id`,
    COUNTIF(st.`uniprot_id` IS NOT NULL) AS targets_in,
    COUNTIF(st.`uniprot_id` IS NULL)     AS nontargets_in
  FROM pathway_members pm
  LEFT JOIN soraf_targets st
         ON pm.`uniprot_id` = st.`uniprot_id`
  GROUP BY pm.`pathway_id`
),

/* 6. Totals required for chi‑squared computation */
totals AS (
  SELECT
    (SELECT COUNT(DISTINCT uniprot_id) FROM all_uniprots) AS N,   -- total proteins
    (SELECT COUNT(DISTINCT uniprot_id) FROM soraf_targets) AS T   -- sorafenib targets
),

/* 7. Assemble contingency table and chi‑squared statistic */
chi_table AS (
  SELECT
    c.`pathway_id`,
    pw.`name`                               AS pathway_name,
    c.`targets_in`                          AS a,
    (t.T - c.`targets_in`)                  AS c_out,
    c.`nontargets_in`                       AS b,
    (t.N - t.T - c.`nontargets_in`)         AS d_out,
    /* χ² = N*(ad - bc)^2 / [(a+b)(c+d)(a+c)(b+d)] */
    t.N * POW( (c.`targets_in` * (t.N - t.T - c.`nontargets_in`) -
                c.`nontargets_in` * (t.T - c.`targets_in`) ), 2 )
      /
      (
        (c.`targets_in` + c.`nontargets_in`) *
        (t.T - c.`targets_in` + t.N - t.T - c.`nontargets_in`) *
        (t.T) *
        (t.N - t.T)
      )                                       AS chi_sq
  FROM counts c
  CROSS JOIN totals t
  JOIN `isb-cgc-bq.reactome_versioned.pathway_v77` pw
    ON c.`pathway_id` = pw.`stable_id`
)

/* 8. Return the three pathways with highest χ² */
SELECT
  pathway_id              AS reactome_pathway_id,
  pathway_name            AS reactome_pathway_name,
  a                       AS targets_in_pathway,
  c_out                   AS targets_outside_pathway,
  b                       AS nontargets_in_pathway,
  d_out                   AS nontargets_outside_pathway
FROM chi_table
ORDER BY chi_sq DESC, pathway_id
LIMIT 3;