WITH counts AS (
    SELECT
        band."cytoband_name",
        MAX(seg."copy_number")                                        AS "max_cn",
        SUM(CASE WHEN seg."copy_number" >= 4 THEN 1 ELSE 0 END)       AS "amp_ct",
        SUM(CASE WHEN seg."copy_number"  = 3 THEN 1 ELSE 0 END)       AS "gain_ct",
        SUM(CASE WHEN seg."copy_number"  = 1 THEN 1 ELSE 0 END)       AS "hetdel_ct"
    FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" seg
    JOIN "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38" band
         ON band."chromosome" = 'chr1'
        AND seg."chromosome"  = band."chromosome"
        AND seg."start_pos"  <= band."hg38_stop"
        AND seg."end_pos"    >= band."hg38_start"
    WHERE seg."project_short_name" = 'TCGA-KIRC'
    GROUP BY band."cytoband_name"
),
ranked AS (
    SELECT
        "cytoband_name",
        RANK() OVER (ORDER BY "amp_ct"    DESC NULLS LAST) AS "rank_amp",
        RANK() OVER (ORDER BY "gain_ct"   DESC NULLS LAST) AS "rank_gain",
        RANK() OVER (ORDER BY "hetdel_ct" DESC NULLS LAST) AS "rank_hetdel"
    FROM counts
),
filtered AS (
    SELECT
        "cytoband_name",
        "rank_amp",
        "rank_gain",
        "rank_hetdel"
    FROM ranked
    WHERE "rank_amp"   <= 11
      AND "rank_gain"  <= 11
      AND "rank_hetdel"<= 11
)
SELECT 'amplification'         AS "event_type", "cytoband_name", "rank_amp"    AS "rank"
FROM   filtered
UNION ALL
SELECT 'gain'                  AS "event_type", "cytoband_name", "rank_gain"   AS "rank"
FROM   filtered
UNION ALL
SELECT 'heterozygous_deletion' AS "event_type", "cytoband_name", "rank_hetdel" AS "rank"
FROM   filtered
ORDER BY "event_type", "rank", "cytoband_name";