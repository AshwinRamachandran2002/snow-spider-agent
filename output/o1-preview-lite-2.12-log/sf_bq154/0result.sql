WITH
expression_data AS (
    SELECT
        expr."ParticipantBarcode",
        AVG(LOG(10, expr."normalized_count" + 1)) AS "IGF2_expression"
    FROM
        "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" AS expr
    WHERE
        expr."Symbol" = 'IGF2'
        AND expr."normalized_count" IS NOT NULL
    GROUP BY
        expr."ParticipantBarcode"
),
clinical_data AS (
    SELECT
        clin."bcr_patient_barcode" AS "ParticipantBarcode",
        clin."icd_o_3_histology"
    FROM
        "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" AS clin
    WHERE
        clin."acronym" = 'LGG'
        AND NOT clin."icd_o_3_histology" REGEXP '^\\[.*\\]$'
),
expression_with_clinical AS (
    SELECT
        e."ParticipantBarcode",
        e."IGF2_expression",
        c."icd_o_3_histology"
    FROM
        expression_data e
        JOIN clinical_data c ON e."ParticipantBarcode" = c."ParticipantBarcode"
),
groups_with_counts AS (
    SELECT
        "icd_o_3_histology",
        COUNT(DISTINCT "ParticipantBarcode") AS "patient_count"
    FROM
        expression_with_clinical
    GROUP BY
        "icd_o_3_histology"
    HAVING
        COUNT(DISTINCT "ParticipantBarcode") > 1
),
filtered_data AS (
    SELECT
        ewc."ParticipantBarcode",
        ewc."IGF2_expression",
        ewc."icd_o_3_histology"
    FROM
        expression_with_clinical ewc
    WHERE
        ewc."icd_o_3_histology" IN (SELECT "icd_o_3_histology" FROM groups_with_counts)
),
data_with_seq_ranks AS (
    SELECT
        fd.*,
        ROW_NUMBER() OVER (ORDER BY fd."IGF2_expression" ASC) AS "seq_rank"
    FROM
        filtered_data fd
),
avg_ranks AS (
    SELECT
        "IGF2_expression",
        AVG("seq_rank") AS "average_rank"
    FROM
        data_with_seq_ranks
    GROUP BY
        "IGF2_expression"
),
data_with_ranks AS (
    SELECT
        dsr."ParticipantBarcode",
        dsr."IGF2_expression",
        dsr."icd_o_3_histology",
        ar."average_rank" AS "rank"
    FROM
        data_with_seq_ranks dsr
        JOIN avg_ranks ar ON dsr."IGF2_expression" = ar."IGF2_expression"
),
group_sums AS (
    SELECT
        "icd_o_3_histology",
        COUNT(*) AS n_i,
        SUM("rank") AS S_i
    FROM
        data_with_ranks
    GROUP BY
        "icd_o_3_histology"
),
overall_sums AS (
    SELECT
        COUNT(*) AS N,
        SUM("rank") AS S,
        SUM("rank" * "rank") AS Q
    FROM
        data_with_ranks
),
gs_sums AS (
    SELECT
        SUM((gs.S_i * gs.S_i) / gs.n_i) AS sum_S_i_sq_over_n_i
    FROM
        group_sums gs
),
H_stat AS (
    SELECT
        ((ov.N - 1) * (gs_sums.sum_S_i_sq_over_n_i - ((ov.S * ov.S) / ov.N))) /
        (ov.Q - ((ov.S * ov.S) / ov.N)) AS H_score
    FROM
        gs_sums CROSS JOIN overall_sums ov
)
SELECT
    (SELECT COUNT(*) FROM group_sums) AS Total_Groups,
    (SELECT COUNT(*) FROM data_with_ranks) AS Total_Samples,
    ROUND(H_score, 4) AS Kruskal_Wallis_H_score
FROM
    H_stat;