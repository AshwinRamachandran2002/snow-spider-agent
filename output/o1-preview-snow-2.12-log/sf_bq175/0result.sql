WITH amplifications AS (
    SELECT cyto."cytoband_name", COUNT(*) AS "frequency"
    FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" AS cnv
    JOIN "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38" AS cyto
      ON cnv."chromosome" = cyto."chromosome"
         AND cnv."start_pos" <= cyto."hg38_stop"
         AND cnv."end_pos" >= cyto."hg38_start"
    WHERE cnv."project_short_name" = 'TCGA-KIRC'
      AND cnv."chromosome" = 'chr1'
      AND cnv."copy_number" > 3
    GROUP BY cyto."cytoband_name"
    ORDER BY "frequency" DESC NULLS LAST
    LIMIT 11
),
gains AS (
    SELECT cyto."cytoband_name", COUNT(*) AS "frequency"
    FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" AS cnv
    JOIN "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38" AS cyto
      ON cnv."chromosome" = cyto."chromosome"
         AND cnv."start_pos" <= cyto."hg38_stop"
         AND cnv."end_pos" >= cyto."hg38_start"
    WHERE cnv."project_short_name" = 'TCGA-KIRC'
      AND cnv."chromosome" = 'chr1'
      AND cnv."copy_number" = 3
    GROUP BY cyto."cytoband_name"
    ORDER BY "frequency" DESC NULLS LAST
    LIMIT 11
),
heterozygous_deletions AS (
    SELECT cyto."cytoband_name", COUNT(*) AS "frequency"
    FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" AS cnv
    JOIN "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38" AS cyto
      ON cnv."chromosome" = cyto."chromosome"
         AND cnv."start_pos" <= cyto."hg38_stop"
         AND cnv."end_pos" >= cyto."hg38_start"
    WHERE cnv."project_short_name" = 'TCGA-KIRC'
      AND cnv."chromosome" = 'chr1'
      AND cnv."copy_number" = 1
    GROUP BY cyto."cytoband_name"
    ORDER BY "frequency" DESC NULLS LAST
    LIMIT 11
)
SELECT "cytoband_name"
FROM (
    SELECT "cytoband_name" FROM amplifications
    INTERSECT
    SELECT "cytoband_name" FROM gains
    INTERSECT
    SELECT "cytoband_name" FROM heterozygous_deletions
) AS common_cytobands
ORDER BY "cytoband_name";