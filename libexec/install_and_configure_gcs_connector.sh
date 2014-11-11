# Copyright 2014 Google Inc. All Rights Reserved.D
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

# Downloads and installs the relevant gcs-connector-<version>.jar.
# Also configures it for use with hadoop.

set -e

# Class name of our cache cleaner
readonly GC_CLEANER='com.google.cloud.hadoop.fs.gcs.GoogleHadoopFileSystemCacheCleaner'

# NFS export table:
readonly ETAB='/var/lib/nfs/etab'

function make_cache_cleaner_script() {
  cat <<EOF
#!/usr/bin/env bash

# See if our NFS export point is mounted:
if  mount | cut -f1 -d' ' | grep -q '$(get_nfs_export_point)' ; then
  # Only start the cleaner if we're also exporting the directory (e.g., we're
  # the master node)
  if test -f '${ETAB}' && grep -q '$(get_nfs_export_point)' '${ETAB}' ; then

    export HADOOP_LOGFILE='gcs-cache-cleaner.log'
    export HADOOP_ROOT_LOGGER='INFO,RFA'

    ${HADOOP_INSTALL_DIR}/bin/hadoop ${GC_CLEANER} > \
        /hadoop/logs/gcs-cache-cleaner.out
  fi
fi
EOF
}

function make_cleaner_crontab() {
  local cleaner=$1

  cat <<EOF
# Run the ${cleaner} script twice every hour at 7 and 37 minutes past the hour
# m h dom mon dow user command
7,37 * * * * hadoop ${cleaner}
EOF
}

if (( ${INSTALL_GCS_CONNECTOR} )) ; then

  if [[ -r "${HADOOP_INSTALL_DIR}/libexec/hadoop-config.sh" ]]; then
    . "${HADOOP_INSTALL_DIR}/libexec/hadoop-config.sh"
  fi
  if [[ -n "${HADOOP_COMMON_LIB_JARS_DIR}" ]] && \
      [[ -n "${HADOOP_PREFIX}" ]]; then
    LIB_JARS_DIR="${HADOOP_PREFIX}/${HADOOP_COMMON_LIB_JARS_DIR}"
  else
    LIB_JARS_DIR="${HADOOP_INSTALL_DIR}/lib"
  fi

  # Grab the connector jarfile, add it to installation /lib directory.
  JARNAME=$(grep -o '[^/]*\.jar' <<< ${GCS_CONNECTOR_JAR})
  LOCAL_JAR="${LIB_JARS_DIR}/${JARNAME}"

  download_bd_resource "${GCS_CONNECTOR_JAR}" "${LOCAL_JAR}"

  echo "export HADOOP_CLASSPATH=\$HADOOP_CLASSPATH:${LOCAL_JAR}" \
      >> ${HADOOP_CONF_DIR}/hadoop-env.sh

  if (( ${ENABLE_NFS_GCS_FILE_CACHE} )); then
    export GCS_METADATA_CACHE_TYPE='FILESYSTEM_BACKED'
    export GCS_FILE_CACHE_DIRECTORY="$(get_nfs_mount_point)"
  else
    export GCS_METADATA_CACHE_TYPE='IN_MEMORY'
    # For IN_MEMORY cache, this directory won't actually be used, but we set
    # it to a sane default for easy manual experimentation of file caching.
    export GCS_FILE_CACHE_DIRECTORY='/tmp/gcs_connector_metadata_cache'
  fi
  bdconfig merge_configurations \
      --configuration_file ${HADOOP_CONF_DIR}/core-site.xml \
      --source_configuration_file gcs-core-template.xml \
      --resolve_environment_variables \
      --create_if_absent \
      --noclobber

  # Install a script that can be used to cleanup filesystem-based GCS caches.
  if [[ "$(hostname -s)" == "${MASTER_HOSTNAME}" \
      && "${ENABLE_NFS_GCS_FILE_CACHE}" -ne 0 ]] ; then
    mkdir -p "${HADOOP_INSTALL_DIR}/google"
    readonly CLEANER="${HADOOP_INSTALL_DIR}/google/clean-caches.sh"
    make_cache_cleaner_script > "${CLEANER}"

    chmod 755 "${CLEANER}"
    chown hadoop:hadoop "${CLEANER}"
    make_cleaner_crontab "${CLEANER}" > "/etc/cron.d/clean-gcs-caches"
  fi
fi
