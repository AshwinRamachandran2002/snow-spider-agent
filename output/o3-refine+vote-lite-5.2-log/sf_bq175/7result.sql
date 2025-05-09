WITH "SEGMENTS" AS (
    SELECT
        s."chromosome",
        s."start_pos",
        s."end_pos",
        s."copy_number"
    FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" s
    WHERE s."project_short_name" = 'TCGA-KIRC'
      AND s."chromosome" = 'chr1'
),
"BANDS" AS (
    SELECT
        b."chromosome",
        b."hg38_start",
        b."hg38_stop",
        b."cytoband_name"
    FROM "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38" b
    WHERE b."chromosome" = 'chr1'
),
"SEG_BAND" AS (
    SELECT
        b."cytoband_name",
        s."copy_number"
    FROM "SEGMENTS" s
    JOIN "BANDS"   b
      ON s."start_pos" <= b."hg38_stop"
     AND s."end_pos"   >= b."hg38_start"
),
"COUNTS" AS (
    SELECT
        "cytoband_name",
        SUM(CASE WHEN "copy_number" >= 4 THEN 1 ELSE 0 END) AS "amplification_cnt",
        SUM(CASE WHEN "copy_number"  = 3 THEN 1 ELSE 0 END) AS "gain_cnt",
        SUM(CASE WHEN "copy_number"  = 1 THEN 1 ELSE 0 END) AS "hetdel_cnt"
    FROM "SEG_BAND"
    GROUP BY "cytoband_name"
),
"RANKED" AS (
    SELECT
        c.*,
        RANK() OVER (ORDER BY c."amplification_cnt" DESC)             AS "amp_rank",
        RANK() OVER (ORDER BY c."gain_cnt"          DESC)             AS "gain_rank",
        RANK() OVER (ORDER BY c."hetdel_cnt"        DESC)             AS "hetdel_rank"
    FROM "COUNTS" c
)
SELECT
    "cytoband_name"
FROM "RANKED"
WHERE "amp_rank"   <= 11
  AND "gain_rank"  <= 11
  AND "hetdel_rank"<= 11
ORDER BY "cytoband_name";