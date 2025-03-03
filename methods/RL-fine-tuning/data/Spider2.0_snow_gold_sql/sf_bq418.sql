WITH targets AS (
  SELECT DISTINCT i."target_uniprotID" AS uniprot_id
  FROM "TARGETOME_REACTOME"."TARGETOME_VERSIONED"."INTERACTIONS_V1" i
  JOIN "TARGETOME_REACTOME"."TARGETOME_VERSIONED"."EXPERIMENTS_V1" e
    ON i."expID" = e."expID"
  WHERE i."drugName" ILIKE '%sorafenib%'
    AND i."targetSpecies" = 'Homo sapiens'
    AND e."exp_assayValueMedian" <= 100
    AND (e."exp_assayValueLow" <= 100 OR e."exp_assayValueLow" IS NULL)
    AND (e."exp_assayValueHigh" <= 100 OR e."exp_assayValueHigh" IS NULL)
),

total_targets AS (
  SELECT COUNT(DISTINCT uniprot_id) AS total_targets
  FROM targets
),

non_targets AS (
  SELECT DISTINCT p."uniprot_id" AS uniprot_id
  FROM "TARGETOME_REACTOME"."REACTOME_VERSIONED"."PHYSICAL_ENTITY_V77" p
  WHERE p."uniprot_id" IS NOT NULL
    AND p."uniprot_id" NOT IN (SELECT uniprot_id FROM targets)
),

total_non_targets AS (
  SELECT COUNT(DISTINCT uniprot_id) AS total_non_targets
  FROM non_targets
),

pathway_proteins AS (
  SELECT DISTINCT pe."pathway_stable_id", p."uniprot_id"
  FROM "TARGETOME_REACTOME"."REACTOME_VERSIONED"."PE_TO_PATHWAY_V77" pe
  JOIN "TARGETOME_REACTOME"."REACTOME_VERSIONED"."PHYSICAL_ENTITY_V77" p
    ON pe."pe_stable_id" = p."stable_id"
  WHERE pe."evidence_code" = 'TAS'
    AND p."uniprot_id" IS NOT NULL
),

pathways AS (
  SELECT DISTINCT pw."stable_id", pw."name"
  FROM "TARGETOME_REACTOME"."REACTOME_VERSIONED"."PATHWAY_V77" pw
  WHERE pw."species" = 'Homo sapiens'
    AND pw."lowest_level" = TRUE
),

t_in_pathway AS (
  SELECT pp."pathway_stable_id", COUNT(DISTINCT t.uniprot_id) AS targets_in_pathway
  FROM pathway_proteins pp
  INNER JOIN targets t ON pp."uniprot_id" = t.uniprot_id
  GROUP BY pp."pathway_stable_id"
),

nt_in_pathway AS (
  SELECT pp."pathway_stable_id", COUNT(DISTINCT nt.uniprot_id) AS non_targets_in_pathway
  FROM pathway_proteins pp
  INNER JOIN non_targets nt ON pp."uniprot_id" = nt.uniprot_id
  GROUP BY pp."pathway_stable_id"
)

SELECT
  pw."name" AS "Pathway_Name",
  COALESCE(t_in_pathway.targets_in_pathway, 0) AS Targets_in_Pathway,
  COALESCE(nt_in_pathway.non_targets_in_pathway, 0) AS NonTargets_in_Pathway,
  total_targets.total_targets - COALESCE(t_in_pathway.targets_in_pathway, 0) AS Targets_outside_Pathway,
  total_non_targets.total_non_targets - COALESCE(nt_in_pathway.non_targets_in_pathway, 0) AS NonTargets_outside_Pathway
FROM pathways pw
LEFT JOIN t_in_pathway ON pw."stable_id" = t_in_pathway."pathway_stable_id"
LEFT JOIN nt_in_pathway ON pw."stable_id" = nt_in_pathway."pathway_stable_id"
CROSS JOIN total_targets, total_non_targets
WHERE COALESCE(t_in_pathway.targets_in_pathway, 0) + COALESCE(nt_in_pathway.non_targets_in_pathway, 0) > 0
ORDER BY (
  (total_targets.total_targets + total_non_targets.total_non_targets) *
  POWER(
    (COALESCE(t_in_pathway.targets_in_pathway, 0) * (total_non_targets.total_non_targets - COALESCE(nt_in_pathway.non_targets_in_pathway, 0)) -
     COALESCE(nt_in_pathway.non_targets_in_pathway, 0) * (total_targets.total_targets - COALESCE(t_in_pathway.targets_in_pathway, 0))
    ), 2)
) /
(
  (COALESCE(t_in_pathway.targets_in_pathway, 0) + COALESCE(nt_in_pathway.non_targets_in_pathway, 0)) *
  ((total_targets.total_targets - COALESCE(t_in_pathway.targets_in_pathway, 0)) + (total_non_targets.total_non_targets - COALESCE(nt_in_pathway.non_targets_in_pathway, 0))) *
  total_targets.total_targets *
  total_non_targets.total_non_targets
) DESC NULLS LAST
LIMIT 3;