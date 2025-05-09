WITH mutated_samples AS (
    SELECT DISTINCT "sample_barcode_tumor" AS "sample_barcode"
    FROM "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."SOMATIC_MUTATION"
    WHERE "project_short_name" = 'TCGA-UCEC'
      AND "Hugo_Symbol" = 'PARP1'
),
expression_data AS (
    SELECT "sample_barcode", "gene_name", LOG(10, 1 + "HTSeq__Counts") AS "log_expr"
    FROM "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."RNASEQ_GENE_EXPRESSION"
    WHERE "project_short_name" = 'TCGA-UCEC'
),
gene_groups AS (
    SELECT ed."gene_name", ed."log_expr",
        CASE WHEN ms."sample_barcode" IS NOT NULL THEN 1 ELSE 0 END AS "group"
    FROM expression_data ed
    LEFT JOIN mutated_samples ms ON ed."sample_barcode" = ms."sample_barcode"
),
gene_statistics AS (
    SELECT "gene_name",
        COUNT(CASE WHEN "group" = 1 THEN 1 END) AS "n1",
        AVG(CASE WHEN "group" = 1 THEN "log_expr" END) AS "mean1",
        VAR_POP(CASE WHEN "group" = 1 THEN "log_expr" END) AS "var1",
        COUNT(CASE WHEN "group" = 0 THEN 1 END) AS "n2",
        AVG(CASE WHEN "group" = 0 THEN "log_expr" END) AS "mean2",
        VAR_POP(CASE WHEN "group" = 0 THEN "log_expr" END) AS "var2"
    FROM gene_groups
    GROUP BY "gene_name"
    HAVING "n1" >= 1 AND "n2" >= 1
),
t_statistics AS (
    SELECT "gene_name",
        ("mean1" - "mean2") / NULLIF(SQRT( ("var1" / "n1") + ("var2" / "n2") ), 0) AS "t_stat"
    FROM gene_statistics
    WHERE ("var1" / "n1") + ("var2" / "n2") != 0
),
gene_entrez AS (
    SELECT DISTINCT "Symbol" AS "gene_name", TRY_TO_NUMBER("Entrez") AS "Entrez_num"
    FROM "TCGA_HG38_DATA_V0"."QOTM"."ORG_HS_EG_DB_V1"
    WHERE TRY_TO_NUMBER("Entrez") IS NOT NULL
),
reactome_entrez AS (
    SELECT rp.*, TRY_TO_NUMBER(rp."ENTREZ") AS "ENTREZ_num"
    FROM "TCGA_HG38_DATA_V0"."QOTM"."REACTOME_A1" rp
    WHERE TRY_TO_NUMBER(rp."ENTREZ") IS NOT NULL
),
gene_pathway AS (
    SELECT ts."gene_name", rp."PATHWAYNAME", ABS(ts."t_stat") AS "abs_t_stat"
    FROM t_statistics ts
    JOIN gene_entrez ge ON ts."gene_name" = ge."gene_name"
    JOIN reactome_entrez rp ON ge."Entrez_num" = rp."ENTREZ_num"
),
pathway_scores AS (
    SELECT "PATHWAYNAME" AS "Pathway_Name",
        SUM("abs_t_stat") AS "Score"
    FROM gene_pathway
    GROUP BY "PATHWAYNAME"
)
SELECT "Pathway_Name", ROUND("Score", 4) AS "Score"
FROM pathway_scores
ORDER BY "Score" DESC NULLS LAST
LIMIT 1;