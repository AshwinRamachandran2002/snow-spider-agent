/*  TCGA‑LUAD & TCGA‑LUSC digital slide microscopy images (SM)
    – JPEG / JPEG‑2000 compressed VOLUME images
    – embedding medium  = “Tissue freezing medium”
    – tissue            = normal (CodeValue 17621005)  OR  tumor (CodeValue 86049000)       */

WITH sm_base AS (   -- 1. SM instances in the two TCGA lung collections, VOLUME images
    SELECT
        d."SeriesInstanceUID",
        d."StudyInstanceUID",
        d."ContainerIdentifier",
        d."PatientID",
        d."collection_id",
        d."SOPInstanceUID",
        d."gcs_url",
        d."Columns",
        d."Rows",
        d."PixelSpacing",
        d."TransferSyntaxUID",
        d."SpecimenDescriptionSequence"
    FROM IDC.IDC_V17."DICOM_ALL"  d
    WHERE d."Modality" = 'SM'
      AND d."collection_id" IN ('tcga_luad','tcga_lusc')
      AND ( d."VolumetricProperties" = 'VOLUME'
            OR d."ImageType" ILIKE '%VOLUME%' )
), ------------------------------------------------------------------
compression_ok AS (   -- 2. retain only JPEG & JPEG2000 compressed images
    SELECT
        b.*,
        CASE
            WHEN b."TransferSyntaxUID" IN
                 ('1.2.840.10008.1.2.4.50','1.2.840.10008.1.2.4.51',
                  '1.2.840.10008.1.2.4.57','1.2.840.10008.1.2.4.70',
                  '1.2.840.10008.1.2.4.80','1.2.840.10008.1.2.4.81')
                 THEN 'jpeg'
            WHEN b."TransferSyntaxUID" IN
                 ('1.2.840.10008.1.2.4.90','1.2.840.10008.1.2.4.91')
                 THEN 'jpeg2000'
            ELSE 'other'
        END AS "compression_type"
    FROM sm_base b
    WHERE b."TransferSyntaxUID" IS NOT NULL
), ------------------------------------------------------------------
specimen_filtered AS ( -- 3.  embedding medium & tissue code directly in JSON text
    SELECT *
    FROM compression_ok
    WHERE "compression_type" IN ('jpeg','jpeg2000')
      AND UPPER( "SpecimenDescriptionSequence"::STRING )          LIKE '%TISSUE FREEZING MEDIUM%'
      AND (   "SpecimenDescriptionSequence"::STRING ILIKE '%"CodeValue":"17621005"%'
           OR "SpecimenDescriptionSequence"::STRING ILIKE '%"CodeValue":"86049000"%')
) ------------------------------------------------------------------
SELECT
    "SeriesInstanceUID"              AS "digital_slide_id",
    "StudyInstanceUID"               AS "case_id",
    "ContainerIdentifier"            AS "physical_slide_id",
    "PatientID"                      AS "patient_id",
    "collection_id",
    "SOPInstanceUID"                 AS "instance_id",
    "gcs_url",
    "Columns"                        AS "width",
    "Rows"                           AS "height",
    "PixelSpacing"::STRING           AS "pixel_spacing",
    "compression_type",
    CASE
        WHEN "SpecimenDescriptionSequence"::STRING ILIKE '%"CodeValue":"17621005"%' THEN 'normal'
        ELSE 'tumor'
    END                               AS "tissue_type",
    CASE
        WHEN "collection_id" = 'tcga_luad' THEN 'luad'
        ELSE                                   'lscc'
    END                               AS "cancer_subtype"
FROM specimen_filtered
ORDER BY "instance_id" ASC;