# Copyright 2014 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS-IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


set -e

if (( ${ENABLE_NFS_GCS_FILE_CACHE} )) ; then

  install_application "nfs-common" "nfs-utils"
  install_application "autofs"

  NFS_MOUNT_POINT="$(get_nfs_mount_point)"
  NFS_EXPORT_POINT="$(get_nfs_export_point)"

  mkdir -p "${NFS_MOUNT_POINT}"
  chown hadoop:hadoop "${NFS_MOUNT_POINT}"
  if ! grep -e "auto.hadoop_gcs_metadata_cache" /etc/auto.master ; then
    echo "/- /etc/auto.hadoop_gcs_metadata_cache nobind" >> /etc/auto.master
  fi

  MOUNT_STRING="/${NFS_MOUNT_POINT} -fstype=nfs,defaults,rw,hard,intr"
  MOUNT_STRING="${MOUNT_STRING} ${MASTER_HOSTNAME}:${NFS_EXPORT_POINT}"
  echo "${MOUNT_STRING}" > /etc/auto.hadoop_gcs_metadata_cache

  service autofs restart
fi
