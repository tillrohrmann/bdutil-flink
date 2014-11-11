CONFIGBUCKET="flink-experiments"
GCE_MACHINE_TYPE="n1-highmem-8"
GCE_ZONE="europe-west1-c"
NUM_WORKERS=1
DEFAULT_FS="hdfs"
USE_ATTACHED_PDS="true"
PREFIX="aljoscha-flink"

COMMAND_GROUPS+=(
  "deploy_flink:
    libexec/deploy_flink.sh
  "
) 

COMMAND_STEPS+=(
  "deploy_flink,*"
)
