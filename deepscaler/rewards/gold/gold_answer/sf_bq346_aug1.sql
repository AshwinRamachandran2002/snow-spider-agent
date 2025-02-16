-- Task: List the collection ID, Patient ID, SOP Instance UID, segmentation category, and segmentation type for segmentations in publicly accessible DICOM data where the Modality is 'SEG' and the SOPClassUID is '1.2.840.10008.5.1.4.1.1.66.4', and each segmentation references its original SOPInstanceUID. Limit the results to 100 rows.

WITH
  sampled_sops AS (
    SELECT
      "collection_id",
      "SeriesDescription",
      "SeriesInstanceUID",
      "SOPInstanceUID" AS "seg_SOPInstanceUID",
      COALESCE(
        "ReferencedSeriesSequence"[0]."ReferencedInstanceSequence"[0]."ReferencedSOPInstanceUID",
        "ReferencedImageSequence"[0]."ReferencedSOPInstanceUID",
        "SourceImageSequence"[0]."ReferencedSOPInstanceUID"
      ) AS "referenced_sop"
    FROM
      "IDC"."IDC_V17"."DICOM_ALL"
    WHERE
      "Modality" = 'SEG'
      AND "SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
      AND "access" = 'Public'
  )
SELECT
  dicom_all."collection_id",
  dicom_all."PatientID",
  dicom_all."SOPInstanceUID",
  REPLACE(segmentations."SegmentedPropertyCategory":CodeMeaning::STRING, '"', '') AS "segmentation_category",
  REPLACE(segmentations."SegmentedPropertyType":CodeMeaning::STRING, '"', '') AS "segmentation_type"
FROM
  sampled_sops
JOIN
  "IDC"."IDC_V17"."DICOM_ALL" AS dicom_all
ON
  sampled_sops."referenced_sop" = dicom_all."SOPInstanceUID"
JOIN
  "IDC"."IDC_V17"."SEGMENTATIONS" AS segmentations
ON
  segmentations."SOPInstanceUID" = sampled_sops."seg_SOPInstanceUID"
LIMIT 100;