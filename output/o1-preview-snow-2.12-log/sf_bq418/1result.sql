WITH
-- Target list: targets associated with 'sorafenib' in 'homo sapiens' meeting assay conditions
target_list AS (
    SELECT DISTINCT i."targetID", i."target_uniprotID"
    FROM "TARGETOME_REACTOME"."TARGETOME_VERSIONED"."INTERACTIONS_V1" i
    JOIN "TARGETOME_REACTOME"."TARGETOME_VERSIONED"."EXPERIMENTS_V1" e
        ON i."expID" = e."expID"
    WHERE i."drugName" ILIKE '%sorafenib%'
        AND i."targetSpecies" ILIKE '%homo sapiens%'
        AND e."exp_assayValueMedian" <= 100
        AND (e."exp_assayValueLow" <= 100 OR e."exp_assayValueLow" IS NULL)
        AND (e."exp_assayValueHigh" <= 100 OR e."exp_assayValueHigh" IS NULL)
),
-- Target physical entities
target_physical_entities AS (
    SELECT DISTINCT t."target_uniprotID", p."stable_id" AS "pe_stable_id"
    FROM target_list t
    JOIN "TARGETOME_REACTOME"."REACTOME_VERSIONED"."PHYSICAL_ENTITY_V77" p
        ON t."target_uniprotID" = p."uniprot_id"
),
-- Target pathways
target_pathways AS (
    SELECT DISTINCT tpe."target_uniprotID", pep."pathway_stable_id"
    FROM target_physical_entities tpe
    JOIN "TARGETOME_REACTOME"."REACTOME_VERSIONED"."PE_TO_PATHWAY_V77" pep
        ON tpe."pe_stable_id" = pep."pe_stable_id"
    WHERE pep."evidence_code" = 'TAS'
),
-- Filtered pathways (lowest_level = TRUE, species 'Homo sapiens')
pathways_filtered AS (
    SELECT DISTINCT pw."stable_id", pw."name"
    FROM "TARGETOME_REACTOME"."REACTOME_VERSIONED"."PATHWAY_V77" pw
    WHERE pw."lowest_level" = TRUE
      AND pw."species" = 'Homo sapiens'
),
-- Background physical entities (non-targets)
background_physical_entities AS (
    SELECT DISTINCT p."uniprot_id", pep."pathway_stable_id"
    FROM "TARGETOME_REACTOME"."REACTOME_VERSIONED"."PHYSICAL_ENTITY_V77" p
    JOIN "TARGETOME_REACTOME"."REACTOME_VERSIONED"."PE_TO_PATHWAY_V77" pep
        ON p."stable_id" = pep."pe_stable_id"
    WHERE pep."evidence_code" = 'TAS'
),
-- Non-target list
non_target_list AS (
    SELECT DISTINCT bpe."uniprot_id"
    FROM background_physical_entities bpe
    LEFT JOIN target_list t ON bpe."uniprot_id" = t."target_uniprotID"
    WHERE t."target_uniprotID" IS NULL
),
-- Pathway counts
pathway_counts AS (
    SELECT
        pw."stable_id" AS pathway_stable_id,
        pw."name" AS pathway_name,
        COUNT(DISTINCT tp."target_uniprotID") AS target_in_pathway,
        COUNT(DISTINCT pnt."uniprot_id") AS nontarget_in_pathway
    FROM pathways_filtered pw
    LEFT JOIN target_pathways tp ON pw."stable_id" = tp."pathway_stable_id"
    LEFT JOIN (
        SELECT bpe."pathway_stable_id", bpe."uniprot_id"
        FROM background_physical_entities bpe
        WHERE bpe."uniprot_id" IN (SELECT "uniprot_id" FROM non_target_list)
    ) pnt ON pw."stable_id" = pnt."pathway_stable_id"
    GROUP BY pw."stable_id", pw."name"
),
-- Totals
totals AS (
    SELECT
        (SELECT COUNT(DISTINCT "target_uniprotID") FROM target_list) AS total_target_count,
        (SELECT COUNT(DISTINCT "uniprot_id") FROM non_target_list) AS total_nontarget_count
),
-- Chi-squared per pathway
pathway_chi_square AS (
    SELECT
        pc.*,
        t.total_target_count,
        t.total_nontarget_count,
        (t.total_target_count + t.total_nontarget_count) AS N,
        (t.total_target_count - pc.target_in_pathway) AS target_not_in_pathway,
        (t.total_nontarget_count - pc.nontarget_in_pathway) AS nontarget_not_in_pathway,
        CASE WHEN 
            (t.total_target_count) > 0 AND
            (t.total_nontarget_count) > 0 AND
            (pc.target_in_pathway + pc.nontarget_in_pathway) > 0 AND
            ((t.total_target_count - pc.target_in_pathway) + (t.total_nontarget_count - pc.nontarget_in_pathway)) > 0
            AND NULLIF(
                (t.total_target_count) * (t.total_nontarget_count) * 
                (pc.target_in_pathway + pc.nontarget_in_pathway) * 
                ((t.total_target_count - pc.target_in_pathway) + (t.total_nontarget_count - pc.nontarget_in_pathway)), 
                0
            ) IS NOT NULL
        THEN
            (
                POWER( ( (pc.target_in_pathway * (t.total_nontarget_count - pc.nontarget_in_pathway)) - ((t.total_target_count - pc.target_in_pathway) * pc.nontarget_in_pathway) ), 2 )
                *
                (t.total_target_count + t.total_nontarget_count)
            ) /
            (
                (t.total_target_count) * (t.total_nontarget_count) * 
                (pc.target_in_pathway + pc.nontarget_in_pathway) * 
                ((t.total_target_count - pc.target_in_pathway) + (t.total_nontarget_count - pc.nontarget_in_pathway))
            )
        ELSE NULL END AS chi_square_stat
    FROM pathway_counts pc
    CROSS JOIN totals t
),
-- Top 3 pathways with highest chi-squared statistic
top3_pathways AS (
    SELECT pathway_stable_id
    FROM pathway_chi_square
    ORDER BY chi_square_stat DESC NULLS LAST
    LIMIT 3
),
-- Targets in top 3 pathways
targets_in_top3 AS (
    SELECT DISTINCT tp."target_uniprotID"
    FROM target_pathways tp
    WHERE tp."pathway_stable_id" IN (SELECT pathway_stable_id FROM top3_pathways)
),
-- Non-targets in top 3 pathways
nontargets_in_top3 AS (
    SELECT DISTINCT bpe."uniprot_id"
    FROM background_physical_entities bpe
    WHERE bpe."uniprot_id" IN (SELECT "uniprot_id" FROM non_target_list)
      AND bpe."pathway_stable_id" IN (SELECT pathway_stable_id FROM top3_pathways)
),
-- Total counts
total_target_count AS (
    SELECT COUNT(DISTINCT "target_uniprotID") AS total_targets
    FROM target_list
),
total_nontarget_count AS (
    SELECT COUNT(DISTINCT "uniprot_id") AS total_nontargets
    FROM non_target_list
)
-- Final counts
SELECT "Location", "Count_of_Targets", "Count_of_NonTargets"
FROM (
    SELECT
        'Within Top 3 Pathways' AS "Location",
        (SELECT COUNT(DISTINCT "target_uniprotID") FROM targets_in_top3) AS "Count_of_Targets",
        (SELECT COUNT(DISTINCT "uniprot_id") FROM nontargets_in_top3) AS "Count_of_NonTargets"
    UNION ALL
    SELECT
        'Outside Top 3 Pathways' AS "Location",
        total_target_count.total_targets - COALESCE((SELECT COUNT(DISTINCT "target_uniprotID") FROM targets_in_top3), 0) AS "Count_of_Targets",
        total_nontarget_count.total_nontargets - COALESCE((SELECT COUNT(DISTINCT "uniprot_id") FROM nontargets_in_top3), 0) AS "Count_of_NonTargets"
    FROM total_target_count
    CROSS JOIN total_nontarget_count
) counts;