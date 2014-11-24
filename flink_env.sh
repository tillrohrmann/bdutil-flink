PROJECT="astral-sorter-757"
GCE_ZONE="europe-west1-c"
CONFIGBUCKET="flink-experiments"
PREFIX="till-flink"

NUM_WORKERS=42
GCE_MACHINE_TYPE="n1-highmem-8"
LOCAL_SSD_COUNT=1
LOCAL_SSD_INTERFACE=NVME

DEFAULT_FS="hdfs"
USE_ATTACHED_PDS="true"
WORKER_ATTACHED_PDS_SIZE_GB=400

GCE_IMAGE="https://www.googleapis.com/compute/v1/projects/gce-nvme/global/images/nvme-backports-debian-7-wheezy-v20140904"

NODEMANAGER_MEMORY_FRACTION=0.90

COMMAND_GROUPS+=(
  "deploy_flink:
    libexec/deploy_flink.sh
  "
) 

COMMAND_STEPS+=(
  "deploy_flink,*"
)
