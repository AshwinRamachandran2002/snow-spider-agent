WITH targets AS (
    SELECT DISTINCT i."target_uniprotID" AS "uniprot_id"
    FROM TARGETOME_REACTOME.TARGETOME_VERSIONED.INTERACTIONS_V1 i
    JOIN TARGETOME_REACTOME.TARGETOME_VERSIONED.EXPERIMENTS_V1 e
      ON i."expID" = e."expID"
    WHERE i."drugName" ILIKE '%sorafenib%' AND i."targetSpecies" ILIKE '%homo sapiens%'
      AND e."exp_assayValueMedian" <= 100
      AND (e."exp_assayValueLow" <= 100 OR e."exp_assayValueLow" IS NULL)
      AND (e."exp_assayValueHigh" <= 100 OR e."exp_assayValueHigh" IS NULL)
),
total_targets AS (
    SELECT COUNT(DISTINCT "uniprot_id") AS "total_targets"
    FROM targets
),
all_uniprot_ids AS (
    SELECT DISTINCT "uniprot_id"
    FROM TARGETOME_REACTOME.REACTOME_VERSIONED.PHYSICAL_ENTITY_V77
    WHERE "uniprot_id" IS NOT NULL
),
non_targets AS (
    SELECT "uniprot_id"
    FROM all_uniprot_ids
    WHERE "uniprot_id" NOT IN (SELECT "uniprot_id" FROM targets)
),
total_non_targets AS (
    SELECT COUNT(DISTINCT "uniprot_id") AS "total_non_targets"
    FROM non_targets
),
pe_to_pathway_tas AS (
    SELECT "pe_stable_id", "pathway_stable_id"
    FROM TARGETOME_REACTOME.REACTOME_VERSIONED.PE_TO_PATHWAY_V77
    WHERE "evidence_code" = 'TAS'
),
pathways AS (
    SELECT "stable_id", "name"
    FROM TARGETOME_REACTOME.REACTOME_VERSIONED.PATHWAY_V77
    WHERE "lowest_level" = TRUE AND "species" = 'Homo sapiens'
),
top3_pathways AS (
    SELECT ps."stable_id"
    FROM (
        SELECT p."stable_id", p."name",
            COUNT(DISTINCT CASE WHEN t."uniprot_id" IS NOT NULL THEN t."uniprot_id" END) AS "target_count",
            COUNT(DISTINCT CASE WHEN nt."uniprot_id" IS NOT NULL THEN nt."uniprot_id" END) AS "non_target_count",
            tt."total_targets", tnt."total_non_targets"
        FROM pathways p
        JOIN pe_to_pathway_tas p2p ON p."stable_id" = p2p."pathway_stable_id"
        JOIN TARGETOME_REACTOME.REACTOME_VERSIONED.PHYSICAL_ENTITY_V77 pe ON p2p."pe_stable_id" = pe."stable_id"
        LEFT JOIN targets t ON pe."uniprot_id" = t."uniprot_id"
        LEFT JOIN non_targets nt ON pe."uniprot_id" = nt."uniprot_id"
        CROSS JOIN total_targets tt
        CROSS JOIN total_non_targets tnt
        GROUP BY p."stable_id", p."name", tt."total_targets", tnt."total_non_targets"
    ) ps
    WHERE ps."target_count" + ps."non_target_count" > 0
    ORDER BY (
        POWER(
            (ps."target_count" * (ps."total_non_targets" - ps."non_target_count") - (ps."total_targets" - ps."target_count") * ps."non_target_count"), 2
        ) * (ps."total_targets" + ps."total_non_targets")
        ) / NULLIF(
            (ps."target_count" + (ps."total_targets" - ps."target_count")) *
            (ps."non_target_count" + (ps."total_non_targets" - ps."non_target_count")) *
            (ps."target_count" + ps."non_target_count") *
            ((ps."total_targets" - ps."target_count") + (ps."total_non_targets" - ps."non_target_count")),
            0
        ) DESC NULLS LAST
    LIMIT 3
),
uniprot_ids_of_targets_in_top3 AS (
    SELECT DISTINCT pe."uniprot_id"
    FROM pe_to_pathway_tas p2p
    JOIN TARGETOME_REACTOME.REACTOME_VERSIONED.PHYSICAL_ENTITY_V77 pe ON p2p."pe_stable_id" = pe."stable_id"
    JOIN targets t ON pe."uniprot_id" = t."uniprot_id"
    WHERE p2p."pathway_stable_id" IN (SELECT "stable_id" FROM top3_pathways)
),
count_targets_in_top3 AS (
    SELECT COUNT(DISTINCT "uniprot_id") AS "count_targets_in_top3"
    FROM uniprot_ids_of_targets_in_top3
),
count_targets_outside_top3 AS (
    SELECT (total_targets."total_targets" - count_targets_in_top3."count_targets_in_top3") AS "count_targets_outside_top3"
    FROM total_targets, count_targets_in_top3
),
uniprot_ids_of_non_targets_in_top3 AS (
    SELECT DISTINCT pe."uniprot_id"
    FROM pe_to_pathway_tas p2p
    JOIN TARGETOME_REACTOME.REACTOME_VERSIONED.PHYSICAL_ENTITY_V77 pe ON p2p."pe_stable_id" = pe."stable_id"
    JOIN non_targets nt ON pe."uniprot_id" = nt."uniprot_id"
    WHERE p2p."pathway_stable_id" IN (SELECT "stable_id" FROM top3_pathways)
),
count_non_targets_in_top3 AS (
    SELECT COUNT(DISTINCT "uniprot_id") AS "count_non_targets_in_top3"
    FROM uniprot_ids_of_non_targets_in_top3
),
count_non_targets_outside_top3 AS (
    SELECT (total_non_targets."total_non_targets" - count_non_targets_in_top3."count_non_targets_in_top3") AS "count_non_targets_outside_top3"
    FROM total_non_targets, count_non_targets_in_top3
)
SELECT "Location", "Count_of_Targets", "Count_of_NonTargets" FROM (
SELECT
    'Within Top 3 Pathways' AS "Location",
    count_targets_in_top3."count_targets_in_top3" AS "Count_of_Targets",
    count_non_targets_in_top3."count_non_targets_in_top3" AS "Count_of_NonTargets"
FROM count_targets_in_top3, count_non_targets_in_top3
UNION ALL
SELECT
    'Outside Top 3 Pathways' AS "Location",
    count_targets_outside_top3."count_targets_outside_top3" AS "Count_of_Targets",
    count_non_targets_outside_top3."count_non_targets_outside_top3" AS "Count_of_NonTargets"
FROM count_targets_outside_top3, count_non_targets_outside_top3
) ORDER BY "Location";