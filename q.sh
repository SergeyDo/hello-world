#!/bin/bash
repo_name=sergey/ssh
image_keep_count=${2:-50}

# Get list of images, assuming sortable by tag (i.e. a date prefix), so we sort
# and output all *but* last 50, that is, if only 40, nothing gets output.  The
# latest tag sorts to the end, so safe from deletion because we +1 the
# keep_count. We ignore images without a tag as they could be dependent layers (?)
keep_idx=$(($image_keep_count + 1))
old_images=$(
  aws ecr list-images --repository-name "${repo_name}" | \
    jq -r "[.imageIds[] | select(.imageTag != null)] | sort_by(.imageTag) | map(\"imageDigest=\" + .imageDigest)[0:-$keep_idx] 
)

if [[ -n $old_images ]]; then
  echo "Cleaning $(echo $old_images | wc -w) old images"
  aws ecr batch-delete-image \
    --repository-name "${repo_name}" \
    --image-ids $old_images
else
  echo "No images to clean (less than $image_keep_count images)"
fi
